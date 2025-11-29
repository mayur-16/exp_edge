import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/supabase_config.dart';
import '../models/user_model.dart';
import '../models/organization.dart';

final authServiceProvider = Provider((ref) => AuthService());

class AuthService {
  final _supabase = SupabaseConfig.client;

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

    return Organization.fromJson(response);
  }
}