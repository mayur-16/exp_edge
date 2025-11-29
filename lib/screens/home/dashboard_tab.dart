import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/organization.dart';
import 'widgets/dashboard_card.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  Organization? _organization;
  int _totalSites = 0;
  int _totalExpenses = 0;
  double _monthlyTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final org = await AuthService().getUserOrganization();
    // In a real app, fetch actual stats from database
    setState(() {
      _organization = org;
      _totalSites = org?.totalSites ?? 0;
      _totalExpenses = org?.totalExpenses ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_organization == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Welcome back!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _organization!.name,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: DashboardCard(
                  title: 'Active Sites',
                  value: _totalSites.toString(),
                  icon: Icons.location_city,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DashboardCard(
                  title: 'Total Expenses',
                  value: _totalExpenses.toString(),
                  icon: Icons.receipt_long,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DashboardCard(
            title: 'Storage Used',
            value: '${(_organization!.storageUsed / (1024 * 1024)).toStringAsFixed(1)} MB',
            subtitle: 'of ${_organization!.maxStorageMb} MB',
            icon: Icons.cloud_outlined,
            color: Colors.purple,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Subscription Status',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatusRow(
                    'Plan',
                    _organization!.subscriptionPlan.toUpperCase(),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusRow(
                    'Status',
                    _organization!.subscriptionStatus.toUpperCase(),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusRow(
                    'Days Remaining',
                    '${_organization!.daysLeft} days',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.tips_and_updates_outlined,
                color: Colors.amber.shade700,
              ),
              title: const Text('Quick Tip'),
              subtitle: const Text(
                'Add expenses regularly to keep track of your project costs in real-time.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[600]),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}