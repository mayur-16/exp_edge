import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/supabase_config.dart';
import '../models/vendor.dart';
import 'auth_service.dart';

final vendorServiceProvider = Provider((ref) => VendorService(ref));

class VendorService {
  final Ref ref;
  final _supabase = SupabaseConfig.client;

  VendorService(this.ref);

  Future<List<Vendor>> getVendors() async {
    final user = await ref.read(authServiceProvider).getCurrentUser();
    if (user == null) return [];

    final response = await _supabase
        .from('vendors')
        .select()
        .eq('organization_id', user.organizationId)
        .order('name', ascending: true);

    return (response as List).map((json) => Vendor.fromJson(json)).toList();
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