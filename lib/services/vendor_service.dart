import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/vendor.dart';
import 'auth_service.dart';

final vendorServiceProvider = Provider((ref) => VendorService(ref));

class VendorService {
  final Ref ref;
  final _supabase = SupabaseConfig.client;

  VendorService(this.ref);

  Future<Map<String, dynamic>> getVendorsPaginated({
    String? searchQuery,
    int page = 1,
    int limit = 20,
  }) async {
    final user = await ref.read(authServiceProvider).getCurrentUser();
    if (user == null) return {'data': [], 'hasMore': false, 'total': 0};

    final offset = (page - 1) * limit;

    // Build query
    var query = _supabase
        .from('vendors')
        .select('*')
        .eq('organization_id', user.organizationId);

    // Search if query provided
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or(
        'name.ilike.%$searchQuery%,'
        'contact_number.ilike.%$searchQuery%,'
        'email.ilike.%$searchQuery%',
      );
    }

    // Apply pagination and ordering, then get count
    final response = await query
        .order('name', ascending: true)
        .range(offset, offset + limit - 1)
        .count(CountOption.exact);

    final vendors = (response.data as List)
        .map((json) => Vendor.fromJson(json))
        .toList();

    final total = response.count ;
    final hasMore = (offset + limit) < total;

    return {
      'data': vendors,
      'hasMore': hasMore,
      'total': total,
      'currentPage': page,
    };
  }

  // Keep old method for backward compatibility
  Future<List<Vendor>> getVendors() async {
    final result = await getVendorsPaginated(page: 1, limit: 1000);
    return result['data'] as List<Vendor>;
  }

  Future<Vendor> createVendor(Vendor vendor) async {
    final response = await _supabase
        .from('vendors')
        .insert(vendor.toJson())
        .select()
        .single();

    return Vendor.fromJson(response);
  }

  Future<void> updateVendor(String id, Map<String, dynamic> updates) async {
    await _supabase.from('vendors').update(updates).eq('id', id);
  }

  Future<void> deleteVendor(String id) async {
    await _supabase.from('vendors').delete().eq('id', id);
  }
}
