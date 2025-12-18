import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/site.dart';
import 'auth_service.dart';

final siteServiceProvider = Provider((ref) => SiteService(ref));

class SiteService {
  final Ref ref;
  final _supabase = SupabaseConfig.client;

  SiteService(this.ref);

  Future<Map<String, dynamic>> getSitesPaginated({
    String? searchQuery,
    int page = 1,
    int limit = 20,
  }) async {
    final user = await ref.read(authServiceProvider).getCurrentUser();
    if (user == null) return {'data': [], 'hasMore': false, 'total': 0};

    final offset = (page - 1) * limit;

    // Build query
    var query = _supabase
        .from('sites')
        .select('*')
        .eq('organization_id', user.organizationId);

    // Search if query provided
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or(
        'name.ilike.%$searchQuery%,'
        'location.ilike.%$searchQuery%',
      );
    }

    // Apply pagination and ordering, then get count
    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1)
        .count(CountOption.exact);

    final sites = (response.data as List)
        .map((json) => Site.fromJson(json))
        .toList();

    final total = response.count ?? 0;
    final hasMore = (offset + limit) < total;

    return {
      'data': sites,
      'hasMore': hasMore,
      'total': total,
      'currentPage': page,
    };
  }

  // Keep old method for backward compatibility
  Future<List<Site>> getSites() async {
    final result = await getSitesPaginated(page: 1, limit: 1000);
    return result['data'] as List<Site>;
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
