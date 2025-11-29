import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/supabase_config.dart';
import '../models/expense.dart';
import 'auth_service.dart';

final expenseServiceProvider = Provider((ref) => ExpenseService(ref));

class ExpenseService {
  final Ref ref;
  final _supabase = SupabaseConfig.client;

  ExpenseService(this.ref);

  Future<List<Expense>> getExpenses({String? siteId}) async {
    final user = await ref.read(authServiceProvider).getCurrentUser();
    if (user == null) return [];

    var query = _supabase
        .from('expenses')
        .select('*, sites(name), vendors(name)')
        .eq('organization_id', user.organizationId);

    if (siteId != null) {
      query = query.eq('site_id', siteId);
    }

    final response = await query.order('expense_date', ascending: false);

    return (response as List).map((json) => Expense.fromJson(json)).toList();
  }

  Future<Expense> createExpense(Expense expense) async {
    final response = await _supabase
        .from('expenses')
        .insert(expense.toJson())
        .select('*, sites(name), vendors(name)')
        .single();

    return Expense.fromJson(response);
  }

  Future<void> updateExpense(String id, Map<String, dynamic> updates) async {
    await _supabase.from('expenses').update(updates).eq('id', id);
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
