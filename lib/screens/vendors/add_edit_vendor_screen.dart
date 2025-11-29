import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/vendor.dart';
import '../../services/vendor_service.dart';
import '../../services/auth_service.dart';

class AddEditVendorScreen extends ConsumerStatefulWidget {
  final Vendor? vendor;

  const AddEditVendorScreen({super.key, this.vendor});

  @override
  ConsumerState<AddEditVendorScreen> createState() => _AddEditVendorScreenState();
}

class _AddEditVendorScreenState extends ConsumerState<AddEditVendorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _contactController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  String? _vendorType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.vendor?.name);
    _contactController = TextEditingController(text: widget.vendor?.contactNumber);
    _emailController = TextEditingController(text: widget.vendor?.email);
    _addressController = TextEditingController(text: widget.vendor?.address);
    _vendorType = widget.vendor?.vendorType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await ref.read(authServiceProvider).getCurrentUser();
      if (user == null) throw Exception('User not found');

      if (widget.vendor == null) {
        // Create new vendor
        final newVendor = Vendor(
          id: '',
          organizationId: user.organizationId,
          name: _nameController.text.trim(),
          contactNumber: _contactController.text.trim().isEmpty
              ? null
              : _contactController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          vendorType: _vendorType,
          createdAt: DateTime.now(),
        );

        await ref.read(vendorServiceProvider).createVendor(newVendor);
      } else {
        // Update existing vendor
        await ref.read(vendorServiceProvider).updateVendor(
          widget.vendor!.id,
          {
            'name': _nameController.text.trim(),
            'contact_number': _contactController.text.trim().isEmpty
                ? null
                : _contactController.text.trim(),
            'email': _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            'address': _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            'vendor_type': _vendorType,
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.vendor == null
                  ? 'Vendor added successfully'
                  : 'Vendor updated successfully',
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
        title: Text(widget.vendor == null ? 'Add Vendor' : 'Edit Vendor'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Vendor Name *',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter vendor name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Contact Number',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty && !value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Address',
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _vendorType,
              decoration: InputDecoration(
                labelText: 'Vendor Type',
                prefixIcon: const Icon(Icons.category_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'material_supplier',
                  child: Text('Material Supplier'),
                ),
                DropdownMenuItem(value: 'labor', child: Text('Labor')),
                DropdownMenuItem(value: 'equipment', child: Text('Equipment')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) => setState(() => _vendorType = value),
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
                      widget.vendor == null ? 'Add Vendor' : 'Update Vendor',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}