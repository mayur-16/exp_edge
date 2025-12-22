import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/expense.dart';
import 'auth_service.dart';

final expenseServiceProvider = Provider((ref) => ExpenseService(ref));

class ExpenseService {
  final Ref ref;
  final _supabase = SupabaseConfig.client;

  ExpenseService(this.ref);

  Future<Map<String, dynamic>> getExpensesPaginated({
    String? siteId,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  }) async {
    final user = await ref.read(authServiceProvider).getCurrentUser();
    if (user == null) return {'data': [], 'hasMore': false, 'total': 0};

    final offset = (page - 1) * limit;

    // Build query
    var query = _supabase
        .from('expenses')
        .select('*, sites(name), vendors(name) , creator:created_by(full_name)')
        .eq('organization_id', user.organizationId);

    // Filter by site if provided
    if (siteId != null) {
      query = query.eq('site_id', siteId);
    }

    // Search if query provided
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or('description.ilike.%$searchQuery%');
    }

    // Apply pagination and ordering, then get count
    final response = await query
        .order('expense_date', ascending: false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1)
        .count(CountOption.exact);

    final expenses = (response.data as List)
        .map((json) => Expense.fromJson(json))
        .toList();

    final total = response.count;
    final hasMore = (offset + limit) < total;

    return {
      'data': expenses,
      'hasMore': hasMore,
      'total': total,
      'currentPage': page,
    };
  }

  // Keep old method for backward compatibility
  Future<List<Expense>> getExpenses({String? siteId}) async {
    final result = await getExpensesPaginated(
      siteId: siteId,
      page: 1,
      limit: 1000, // Large limit for non-paginated calls
    );
    return result['data'] as List<Expense>;
  }

  Future<Expense> createExpense(Expense expense) async {
      final user = await ref.read(authServiceProvider).getCurrentUser();
    if (user == null) throw Exception('User not authenticated');
    final response = await _supabase
        .from('expenses')
        .insert({ ...expense.toJson(), 
        'created_by': user.id, })
        .select('*, sites(name), vendors(name) , creator:created_by(full_name)')
        .single();

    return Expense.fromJson(response);
  }

  Future<void> updateExpense(String id, Map<String, dynamic> updates) async {
          final user = await ref.read(authServiceProvider).getCurrentUser();
    if (user == null) throw Exception('User not authenticated');
    await _supabase.from('expenses').update({...updates , 'created_by': user.id}).eq('id', id);
  }

  Future<void> deleteExpense(String id) async {
    await _supabase.from('expenses').delete().eq('id', id);
  }

  Future<Map<String, double>> getExpenseSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final user = await ref.read(authServiceProvider).getCurrentUser();
    if (user == null) return {};

    var query = _supabase
        .from('expenses')
        .select('category, amount')
        .eq('organization_id', user.organizationId);

    if (startDate != null) {
      query = query.gte('expense_date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('expense_date', endDate.toIso8601String());
    }

    final response = await query;

    Map<String, double> summary = {};
    for (var item in response) {
      final category = item['category'] as String;
      final amount = (item['amount'] as num).toDouble();
      summary[category] = (summary[category] ?? 0) + amount;
    }

    return summary;
  }
}
