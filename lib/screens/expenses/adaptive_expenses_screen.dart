import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';
import '../../services/expense_service.dart';
import '../../services/auth_service.dart';
import '../../services/export_service.dart';
import '../../core/responsive/responsive_layout.dart';
import 'add_edit_expense_screen.dart';
import 'expense_detail_screen.dart';
import 'dart:async';

class AdaptiveExpensesScreen extends ConsumerStatefulWidget {
  final String? siteId;

  const AdaptiveExpensesScreen({super.key, this.siteId});

  @override
  ConsumerState<AdaptiveExpensesScreen> createState() =>
      _AdaptiveExpensesScreenState();
}

class _AdaptiveExpensesScreenState
    extends ConsumerState<AdaptiveExpensesScreen> {
  List<Expense> _expenses = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

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
      final result =
          await ref.read(expenseServiceProvider).getExpensesPaginated(
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
      final result =
          await ref.read(expenseServiceProvider).getExpensesPaginated(
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
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _searchQuery = query);
        _loadExpenses();
      }
    });
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
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Column(
      children: [
        // Header Section
        Container(
          padding: ResponsiveGrid.getPadding(context),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              // Search and Actions
              Row(
                children: [
                  Expanded(
                    flex: isDesktop ? 3 : 1,
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (isDesktop) ...[
                    ElevatedButton.icon(
                      onPressed: _expenses.isEmpty
                          ? null
                          : () async {
                              final org = await ref
                                  .read(authServiceProvider)
                                  .getUserOrganization();
                              if (org != null) {
                                await ExportService.exportExpensesToExcel(
                                  expenses: _filteredExpenses,
                                  organization: org,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Expenses exported successfully'),
                                    ),
                                  );
                                }
                              }
                            },
                      icon: const Icon(Icons.download),
                      label: const Text('Export'),
                    ),
                    const SizedBox(width: 8),
                  ],
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
                    label: Text(isDesktop ? 'Add Expense' : 'Add'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Summary Cards
              if (isDesktop)
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Expenses',
                        _currencyFormat.format(_totalAmount),
                        Icons.account_balance_wallet,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Count',
                        '$_totalCount',
                        Icons.receipt_long,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Average',
                        _totalCount > 0
                            ? _currencyFormat
                                .format(_totalAmount / _totalCount)
                            : '₹0.00',
                        Icons.analytics,
                        Colors.green,
                      ),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                          Text(
                            _currencyFormat.format(_totalAmount),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_totalCount expense${_totalCount != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Category Filters
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

        // Data Table/List
        Expanded(
          child: _isLoading && _expenses.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _expenses.isEmpty
                  ? _buildEmptyState()
                  : isDesktop
                      ? _buildDesktopTable()
                      : _buildMobileList(),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Column(
            children: [
              DataTable(
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Site')),
                  DataColumn(label: Text('Vendor')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Description')),
                  DataColumn(label: Text('Amount'), numeric: true),
                  DataColumn(label: Text('Receipt')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _filteredExpenses.map((expense) {
                  return DataRow(
                    cells: [
                      DataCell(Text(DateFormat('dd/MM/yyyy')
                          .format(expense.expenseDate))),
                      DataCell(Text(expense.siteName ?? 'Unknown')),
                      DataCell(Text(expense.vendorName ?? 'N/A')),
                      DataCell(_buildCategoryBadge(expense.category)),
                      DataCell(
                        SizedBox(
                          width: 200,
                          child: Text(
                            expense.description,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text(_currencyFormat.format(expense.amount))),
                      DataCell(Icon(
                        expense.receiptUrl != null
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: expense.receiptUrl != null
                            ? Colors.green
                            : Colors.grey,
                        size: 20,
                      )),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility, size: 20),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ExpenseDetailScreen(expense: expense),
                                  ),
                                );
                                if (result == true) _loadExpenses();
                              },
                              tooltip: 'View Details',
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddEditExpenseScreen(
                                        expense: expense),
                                  ),
                                );
                                if (result == true) _loadExpenses();
                              },
                              tooltip: 'Edit',
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              if (_isLoadingMore)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return RefreshIndicator(
      onRefresh: _loadExpenses,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
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
                    color:
                        _getCategoryColor(expense.category).withOpacity(0.1),
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
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM yyyy')
                              .format(expense.expenseDate),
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        if (expense.receiptUrl != null)
                          Icon(Icons.attach_file,
                              size: 14, color: Colors.blue[600]),
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
    );
  }

  Widget _buildCategoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getCategoryColor(category).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: _getCategoryColor(category),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 80, color: Colors.grey[400]),
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
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'labor':
        return Colors.blue;
      case 'materials':
        return Colors.orange;
      case 'equipment':
        return Colors.purple;
      case 'transport':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'labor':
        return Icons.people;
      case 'materials':
        return Icons.inventory_2;
      case 'equipment':
        return Icons.construction;
      case 'transport':
        return Icons.local_shipping;
      default:
        return Icons.receipt;
    }
  }
}