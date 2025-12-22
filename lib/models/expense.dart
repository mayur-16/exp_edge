class Expense {
  final String id;
  final String organizationId;
  final String siteId;
  final String? vendorId;
  final double amount;
  final String description;
  final String category;
  final DateTime expenseDate;
  final String? receiptUrl;
  final DateTime createdAt;
  final String? createdBy;

  // Additional fields for display
  String? siteName;
  String? vendorName;
  String? createdByName;

  Expense({
    required this.id,
    required this.organizationId,
    required this.siteId,
    this.vendorId,
    required this.amount,
    required this.description,
    required this.category,
    required this.expenseDate,
    this.receiptUrl,
    this.createdBy,
    required this.createdAt,
    this.siteName,
    this.vendorName,
    this.createdByName,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      organizationId: json['organization_id'],
      siteId: json['site_id'],
      vendorId: json['vendor_id'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'],
      category: json['category'],
      expenseDate: DateTime.parse(json['expense_date']),
      receiptUrl: json['receipt_url'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      siteName: json['sites']?['name'],
      vendorName: json['vendors']?['name'],
      // Handle both nested object and direct field
      createdByName: json['creator']?['full_name'] ?? json['creator_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organization_id': organizationId,
      'site_id': siteId,
      'vendor_id': vendorId,
      'amount': amount,
      'description': description,
      'category': category,
      'expense_date': expenseDate.toIso8601String().split('T')[0],
      'receipt_url': receiptUrl,
    };
  }
}
