import 'package:exp_edge/services/biometric_service.dart';
import 'package:exp_edge/services/contactus_service.dart';
import 'package:exp_edge/services/expense_service.dart';
import 'package:exp_edge/services/export_service.dart';
import 'package:exp_edge/services/site_service.dart';
import 'package:exp_edge/services/vendor_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../models/organization.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  UserModel? _user;
  Organization? _organization;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = await ref.read(authServiceProvider).getCurrentUser();
      final org = await ref.read(authServiceProvider).getUserOrganization();

      if (mounted) {
        setState(() {
          _user = user;
          _organization = org;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    }
  }

Future<void> _logout() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800,foregroundColor: Colors.white,),
          child: const Text('Logout'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    await BiometricService.clearCredentials(); // Add this line
    await ref.read(authServiceProvider).signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null || _organization == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Error loading profile')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Text(
                      _user!.fullName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _user!.fullName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _user!.role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // User Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'User Information',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Full Name', _user!.fullName),
                    const Divider(height: 24),
                    _buildInfoRow('Email', _user!.email),
                    const Divider(height: 24),
                    _buildInfoRow('Role', _user!.role.toUpperCase()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Organization Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.business_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Organization',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Name', _organization!.name),
                    const Divider(height: 24),
                    _buildInfoRow('Email', _organization!.email),
                    if (_organization!.phone != null) ...[
                      const Divider(height: 24),
                      _buildInfoRow('Phone', _organization!.phone!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Subscription Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.card_membership_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Subscription',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'Plan',
                      _organization!.subscriptionPlan.toUpperCase(),
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      'Status',
                      _organization!.subscriptionStatus.toUpperCase(),
                      valueColor: _organization!.isExpired
                          ? Colors.red
                          : Colors.green,
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      'Days Remaining',
                      '${_organization!.daysLeft} days',
                      valueColor: _organization!.showWarning
                          ? Colors.orange
                          : null,
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      'Expires On',
                      _organization!.subscriptionStatus == 'trial'
                          ? _formatDate(_organization!.trialEndDate)
                          : _formatDate(_organization!.subscriptionEndDate),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Biometric Settings Card
            FutureBuilder<bool>(
              future: BiometricService.canUseBiometrics(),
              builder: (context, snapshot) {
                if (snapshot.data != true) return const SizedBox.shrink();

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.fingerprint,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Biometric Login',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<bool>(
                          future: BiometricService.isBiometricEnabled(),
                          builder: (context, enabledSnapshot) {
                            final isEnabled = enabledSnapshot.data ?? false;

                            return SwitchListTile(
                              value: isEnabled,
                              onChanged: (value) async {
                                if (value) {
                                  print('Enabling biometric');
                                  // Enable biometric
                                  final authenticated =
                                      await BiometricService.authenticate();
                                      print('Authenticated: $authenticated');
                                  if (authenticated) {
                                    await BiometricService.setBiometricEnabled(
                                      true,
                                    );
                                    setState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Biometric login enabled',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } else {
                                  // Disable biometric
                                  await BiometricService.setBiometricEnabled(
                                    false,
                                  );
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Biometric login disabled'),
                                    ),
                                  );
                                }
                              },
                              title: const Text('Enable Biometric Login'),
                              subtitle: Text(
                                isEnabled
                                    ? 'Login with fingerprint/face ID'
                                    : 'Use biometrics for quick login',
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Usage Stats Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Usage Statistics',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'Sites',
                      '${_organization!.totalSites} / ${_organization!.maxSites}',
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      'Expenses',
                      '${_organization!.totalExpenses} / ${_organization!.maxExpenses}',
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      'Storage',
                      '${(_organization!.storageUsed / (1024 * 1024)).toStringAsFixed(1)} MB / ${_organization!.maxStorageMb} MB',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

// Export Data Card
Card(
  child: Column(
    children: [
      ListTile(
        leading: Icon(
          Icons.file_download,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Export Data'),
        subtitle: const Text('Download data for to your system'),
      ),
      const Divider(height: 1),
      ListTile(
        leading: const Icon(Icons.receipt_long),
        title: const Text('Export Expenses'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          // Show date range picker
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context),
                child: child!,
              );
            },
          );

          if (picked != null) {
            final expenses = await ref.read(expenseServiceProvider).getExpenses();
            final filtered = expenses.where((e) {
              return e.expenseDate.isAfter(picked.start) &&
                  e.expenseDate.isBefore(picked.end.add(const Duration(days: 1)));
            }).toList();

            if (_organization != null) {
              await ExportService.exportExpensesToExcel(
                expenses: filtered,
                organization: _organization!,
                startDate: picked.start,
                endDate: picked.end,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Expenses exported successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          }
        },
      ),
      ListTile(
        leading: const Icon(Icons.location_city),
        title: const Text('Export Sites'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final sites = await ref.read(siteServiceProvider).getSites();
          if (_organization != null) {
            await ExportService.exportSitesToExcel(
              sites: sites,
              organization: _organization!,
            );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sites exported successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        },
      ),
      ListTile(
        leading: const Icon(Icons.people),
        title: const Text('Export Vendors'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final vendors = await ref.read(vendorServiceProvider).getVendors();
          if (_organization != null) {
            await ExportService.exportVendorsToExcel(
              vendors: vendors,
              organization: _organization!,
            );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vendors exported successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        },
      ),
    ],
  ),
),
            const SizedBox(height: 24),

            // Contact Support Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.support_agent,
                      size: 48,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Need Help?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Contact us for support or subscription renewal',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ContactusService.openWhatsApp(context: context);
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('Contact Support'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Logout', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Version Info
            Center(
              child: Text(
                'Exp Edge v1.0.0',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: valueColor,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}
