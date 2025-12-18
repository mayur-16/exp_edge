import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';
import '../../services/expense_service.dart';
import '../../services/auth_service.dart';
import '../../services/export_service.dart';
import 'add_edit_expense_screen.dart';
import 'expense_detail_screen.dart';
import 'dart:async';

class ExpensesScreen extends ConsumerStatefulWidget {
  final String? siteId;

  const ExpensesScreen({super.key, this.siteId});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  List<Expense> _expenses = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
  
  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 20;
  bool _hasMore = true;
  int _totalCount = 0;
  
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoadingMore && _hasMore) {
          _loadMoreExpenses();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _expenses = [];
    });

    try {
      final result = await ref.read(expenseServiceProvider).getExpensesPaginated(
        siteId: widget.siteId,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        page: _currentPage,
        limit: _itemsPerPage,
      );

      if (mounted) {
        setState(() {
          _expenses = result['data'] as List<Expense>;
          _hasMore = result['hasMore'] as bool;
          _totalCount = result['total'] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading expenses: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreExpenses() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final result = await ref.read(expenseServiceProvider).getExpensesPaginated(
        siteId: widget.siteId,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        page: _currentPage + 1,
        limit: _itemsPerPage,
      );

      if (mounted) {
        setState(() {
          _currentPage++;
          _expenses.addAll(result['data'] as List<Expense>);
          _hasMore = result['hasMore'] as bool;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    // Debounce search
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _searchQuery = query);
        _loadExpenses();
      }
    });
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(expenseServiceProvider).deleteExpense(expense.id);
        _loadExpenses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting expense: $e')),
          );
        }
      }
    }
  }

  List<Expense> get _filteredExpenses {
    if (_selectedCategory == 'all') return _expenses;
    return _expenses.where((e) => e.category == _selectedCategory).toList();
  }

  double get _totalAmount {
    return _filteredExpenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _expenses.isEmpty) {
      return Scaffold(
        appBar: widget.siteId != null ? AppBar(title: const Text('Site Expenses')) : null,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: widget.siteId != null ? AppBar(title: const Text('Site Expenses')) : null,
      body: Column(
        children: [
          if (_expenses.isEmpty && !_isLoading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isEmpty ? 'No expenses yet' : 'No expenses found',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchQuery.isEmpty
                          ? 'Add your first expense'
                          : 'Try a different search term',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    if (_searchQuery.isEmpty) ...[
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddEditExpenseScreen(),
                            ),
                          );
                          if (result == true) _loadExpenses();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Expense'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else ...[
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search expenses...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() => _searchQuery = '');
                            _loadExpenses();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            // Total Amount and Filters
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.siteId != null ? 'Site Total' : 'Total',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(_totalAmount),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_totalCount total expense${_totalCount != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('all', 'All'),
                        _buildCategoryChip('labor', 'Labor'),
                        _buildCategoryChip('materials', 'Materials'),
                        _buildCategoryChip('equipment', 'Equipment'),
                        _buildCategoryChip('transport', 'Transport'),
                        _buildCategoryChip('other', 'Other'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Header with Add button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_filteredExpenses.length} Expense${_filteredExpenses.length != 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final org = await ref.read(authServiceProvider).getUserOrganization();
                      if (org != null && _expenses.isNotEmpty) {
                        await ExportService.exportExpensesToExcel(
                          expenses: _filteredExpenses,
                          organization: org,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Expenses exported successfully')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.download),
                    tooltip: 'Export to Excel',
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddEditExpenseScreen(),
                        ),
                      );
                      if (result == true) _loadExpenses();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ),

            // Expenses List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadExpenses,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredExpenses.length + (_hasMore || _isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _filteredExpenses.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final expense = _filteredExpenses[index];
                    return InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExpenseDetailScreen(expense: expense),
                          ),
                        );
                        if (result == true) _loadExpenses();
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(expense.category).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getCategoryIcon(expense.category),
                              color: _getCategoryColor(expense.category),
                            ),
                          ),
                          title: Text(
                            expense.description,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(expense.siteName ?? 'Unknown Site',
                                  style: TextStyle(color: Colors.grey[600])),
                              if (expense.vendorName != null) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.person, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      expense.vendorName!,
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(expense.expenseDate),
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                  const SizedBox(width: 12),
                                  if (expense.receiptUrl != null)
                                    Icon(Icons.attach_file, size: 14, color: Colors.blue[600]),
                                ],
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _currencyFormat.format(expense.amount),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedCategory = category);
        },
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'labor': return Colors.blue;
      case 'materials': return Colors.orange;
      case 'equipment': return Colors.purple;
      case 'transport': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'labor': return Icons.people;
      case 'materials': return Icons.inventory_2;
      case 'equipment': return Icons.construction;
      case 'transport': return Icons.local_shipping;
      default: return Icons.receipt;
    }
  }
}