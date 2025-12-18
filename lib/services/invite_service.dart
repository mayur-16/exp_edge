import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/supabase_config.dart';

final inviteServiceProvider = Provider((ref) => InviteService());

class InviteService {
  final _supabase = SupabaseConfig.client;

  Future<Map<String, dynamic>> validateInviteToken(String token) async {
    try {
      final response = await _supabase.rpc('validate_invite_token', params: {
        'token_input': token,
      });

      if (response == null || response.isEmpty) {
        return {'isValid': false};
      }

      final data = response[0];
      return {
        'isValid': data['is_valid'] as bool,
        'organizationId': data['organization_id'],
        'organizationName': data['organization_name'],
        'email': data['email'],
        'role': data['role'],
      };
    } catch (e) {
      print('Error validating invite token: $e');
      return {'isValid': false, 'error': e.toString()};
    }
  }
}