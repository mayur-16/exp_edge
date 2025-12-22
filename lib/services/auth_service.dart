import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/supabase_config.dart';
import '../models/user_model.dart';
import '../models/organization.dart';

final authServiceProvider = Provider((ref) => AuthService());

class AuthService {
  final _supabase = SupabaseConfig.client;

  Future<Map<String, dynamic>> signUpWithInvite({
  required String token,
  required String fullName,
  required String password,
}) async {
  try {
    // Validate invite first
    final inviteResponse = await _supabase.rpc('validate_invite_token', params: {
      'token_input': token,
    });

    if (inviteResponse == null || inviteResponse.isEmpty) {
      throw Exception('Invalid invitation token');
    }

    final inviteData = inviteResponse[0];
    
    if (!inviteData['is_valid']) {
      throw Exception('Invitation has expired or been used');
    }

    final email = inviteData['email'] as String;
    final organizationId = inviteData['organization_id'] as String;
    final role = inviteData['role'] as String;

    // Create auth user
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (authResponse.user == null) {
      throw Exception('Failed to create user');
    }

    // Create user profile
    await _supabase.from('users').insert({
      'id': authResponse.user!.id,
      'organization_id': organizationId,
      'email': email,
      'full_name': fullName,
      'role': role,
    });

    // Mark invite as used
    await _supabase
        .from('invite_tokens')
        .update({'used': true})
        .eq('token', token);

    return {'success': true, 'message': 'Account created successfully'};
  } catch (e) {
    return {'success': false, 'message': e.toString()};
  }
}

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    required String organizationName,
    String? phone,
  }) async {
    try {
      // Create auth user
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create user');
      }

      // Create organization
      final orgResponse = await _supabase
          .from('organizations')
          .insert({
            'name': organizationName,
            'email': email,
            'phone': phone,
          })
          .select()
          .single();

      // Create user profile
      await _supabase.from('users').insert({
        'id': authResponse.user!.id,
        'organization_id': orgResponse['id'],
        'email': email,
        'full_name': fullName,
        'role': 'admin',
      });

      return {'success': true, 'message': 'Account created successfully'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return {'success': true, 'message': 'Login successful'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  String? get currentUserId => _supabase.auth.currentUser?.id;

  bool get isSignedIn => _supabase.auth.currentUser != null;

  Future<UserModel?> getCurrentUser() async {
    if (!isSignedIn) return null;

    final response = await _supabase
        .from('users')
        .select()
        .eq('id', currentUserId!)
        .single();

    return UserModel.fromJson(response);
  }

  Future<Organization?> getUserOrganization() async {
    if (!isSignedIn) return null;

    final user = await getCurrentUser();
    if (user == null) return null;

    final response = await _supabase
        .from('organizations')
        .select()
        .eq('id', user.organizationId)
        .single();

    final org = Organization.fromJson(response);
    
    // ✨ AUTO-UPDATE expired subscriptions
    await _checkAndUpdateSubscriptionStatus(org);

    return org;
  }


    /// Auto-update subscription status if expired
  /// This runs every time user opens the app
  Future<void> _checkAndUpdateSubscriptionStatus(Organization org) async {
    // Skip if already marked as expired
    if (org.subscriptionStatus == 'expired') return;

    final now = DateTime.now();
    bool needsUpdate = false;

    // Check trial expiration
    if (org.subscriptionStatus == 'trial' && 
        org.trialEndDate != null && 
        now.isAfter(org.trialEndDate!)) {
      needsUpdate = true;
    }

    // Check active subscription expiration
    if (org.subscriptionStatus == 'active' && 
        org.subscriptionEndDate != null && 
        now.isAfter(org.subscriptionEndDate!)) {
      needsUpdate = true;
    }

    // Update database if expired
    if (needsUpdate) {
      try {
        await _supabase
            .from('organizations')
            .update({'subscription_status': 'expired'})
            .eq('id', org.id);
        
        print('✅ Auto-updated organization ${org.id} status to expired');
      } catch (e) {
        print('⚠️ Failed to update subscription status: $e');
        // Don't throw - app still works with org.isExpired calculation
      }
    }
  }
  
}