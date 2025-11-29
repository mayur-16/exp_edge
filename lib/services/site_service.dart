import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/supabase_config.dart';
import '../models/site.dart';
import 'auth_service.dart';

final siteServiceProvider = Provider((ref) => SiteService(ref));

class SiteService {
  final Ref ref;
  final _supabase = SupabaseConfig.client;

  SiteService(this.ref);

  Future<List<Site>> getSites() async {
    final user = await ref.read(authServiceProvider).getCurrentUser();
    if (user == null) return [];

    final response = await _supabase
        .from('sites')
        .select()
        .eq('organization_id', user.organizationId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Site.fromJson(json)).toList();
  }

  Future<Site> createSite(Site site) async {
    final response = await _supabase
        .from('sites')
        .insert(site.toJson())
        .select()
        .single();

    return Site.fromJson(response);
  }

  Future<void> updateSite(String id, Map<String, dynamic> updates) async {
    await _supabase.from('sites').update(updates).eq('id', id);
  }

  Future<void> deleteSite(String id) async {
    await _supabase.from('sites').delete().eq('id', id);
  }
}
