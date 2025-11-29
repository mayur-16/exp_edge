import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../models/expense.dart';
import '../../models/site.dart';
import '../../models/vendor.dart';
import '../../services/expense_service.dart';
import '../../services/site_service.dart';
import '../../services/vendor_service.dart';
import '../../services/auth_service.dart';
import '../../core/config/supabase_config.dart';

class AddEditExpenseScreen extends ConsumerStatefulWidget {
  final Expense? expense;

  const AddEditExpenseScreen({super.key, this.expense});

  @override
  ConsumerState<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends ConsumerState<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  
  String? _selectedSiteId;
  String? _selectedVendorId;
  String _selectedCategory = 'materials';
  DateTime _expenseDate = DateTime.now();
  
  File? _receiptImage;
  String? _existingReceiptUrl;
  bool _isLoading = false;
  
  List<Site> _sites = [];
  List<Vendor> _vendors = [];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.expense?.amount.toString(),
    );
    _descriptionController = TextEditingController(
      text: widget.expense?.description,
    );
    _selectedSiteId = widget.expense?.siteId;
    _selectedVendorId = widget.expense?.vendorId;
    _selectedCategory = widget.expense?.category ?? 'materials';
    _expenseDate = widget.expense?.expenseDate ?? DateTime.now();
    _existingReceiptUrl = widget.expense?.receiptUrl;
    
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final sites = await ref.read(siteServiceProvider).getSites();
      final vendors = await ref.read(vendorServiceProvider).getVendors();
      
      if (mounted) {
        setState(() {
          _sites = sites;
          _vendors = vendors;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Compress image
        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          pickedFile.path,
          '${pickedFile.path}_compressed.jpg',
          quality: 85,
        );

        if (compressedFile != null) {
          setState(() {
            _receiptImage = File(compressedFile.path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadReceipt() async {
    if (_receiptImage == null) return _existingReceiptUrl;

    try {
      final user = await ref.read(authServiceProvider).getCurrentUser();
      if (user == null) throw Exception('User not found');

      final fileName = '${user.organizationId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await _receiptImage!.readAsBytes();

      await SupabaseConfig.client.storage
          .from('receipts')
          .uploadBinary(fileName, bytes);

      return SupabaseConfig.client.storage
          .from('receipts')
          .getPublicUrl(fileName);
    } catch (e) {
      throw Exception('Failed to upload receipt: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSiteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a site')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await ref.read(authServiceProvider).getCurrentUser();
      if (user == null) throw Exception('User not found');

      // Upload receipt if there's a new image
      String? receiptUrl;
      if (_receiptImage != null) {
        receiptUrl = await _uploadReceipt();
      } else {
        receiptUrl = _existingReceiptUrl;
      }

      if (widget.expense == null) {
        // Create new expense
        final newExpense = Expense(
          id: '',
          organizationId: user.organizationId,
          siteId: _selectedSiteId!,
          vendorId: _selectedVendorId,
          amount: double.parse(_amountController.text.trim()),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          expenseDate: _expenseDate,
          receiptUrl: receiptUrl,
          createdAt: DateTime.now(),
        );

        await ref.read(expenseServiceProvider).createExpense(newExpense);
      } else {
        // Update existing expense
        await ref.read(expenseServiceProvider).updateExpense(
          widget.expense!.id,
          {
            'site_id': _selectedSiteId,
            'vendor_id': _selectedVendorId,
            'amount': double.parse(_amountController.text.trim()),
            'description': _descriptionController.text.trim(),
            'category': _selectedCategory,
            'expense_date': _expenseDate.toIso8601String().split('T')[0],
            'receipt_url': receiptUrl,
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.expense == null
                  ? 'Expense added successfully'
                  : 'Expense updated successfully',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense == null ? 'Add Expense' : 'Edit Expense'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _selectedSiteId,
              decoration: InputDecoration(
                labelText: 'Site *',
                prefixIcon: const Icon(Icons.location_city_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _sites.map((site) {
                return DropdownMenuItem(
                  value: site.id,
                  child: Text(site.name),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedSiteId = value),
              validator: (value) {
                if (value == null) return 'Please select a site';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount *',
                prefixIcon: const Icon(Icons.currency_rupee),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description *',
                prefixIcon: const Icon(Icons.description_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category *',
                prefixIcon: const Icon(Icons.category_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'labor', child: Text('Labor')),
                DropdownMenuItem(value: 'materials', child: Text('Materials')),
                DropdownMenuItem(value: 'equipment', child: Text('Equipment')),
                DropdownMenuItem(value: 'transport', child: Text('Transport')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedCategory = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedVendorId,
              decoration: InputDecoration(
                labelText: 'Vendor (Optional)',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _vendors.map((vendor) {
                return DropdownMenuItem(
                  value: vendor.id,
                  child: Text(vendor.name),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedVendorId = value),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _expenseDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _expenseDate = date);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Expense Date *',
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '${_expenseDate.day}/${_expenseDate.month}/${_expenseDate.year}',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_outlined),
                        const SizedBox(width: 8),
                        const Text(
                          'Receipt/Invoice',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _showImageSourceDialog,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    if (_receiptImage != null) ...[
                      const SizedBox(height: 12),
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _receiptImage!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              onPressed: () {
                                setState(() => _receiptImage = null);
                              },
                              icon: const Icon(Icons.close),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (_existingReceiptUrl != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.attach_file, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('Receipt attached'),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() => _existingReceiptUrl = null);
                            },
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Text(
                        'No receipt attached',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.expense == null ? 'Add Expense' : 'Update Expense',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
