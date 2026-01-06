
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/organization.dart';
import '../../core/responsive/responsive_layout.dart';
import 'widgets/dashboard_card.dart';

class AdaptiveDashboardTab extends StatefulWidget {
  const AdaptiveDashboardTab({super.key});

  @override
  State<AdaptiveDashboardTab> createState() => _AdaptiveDashboardTabState();
}

class _AdaptiveDashboardTabState extends State<AdaptiveDashboardTab> {
  Organization? _organization;
  int _totalSites = 0;
  int _totalExpenses = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final org = await AuthService().getUserOrganization();

      if (org == null) {
        setState(() {
          _errorMessage = 'Organization not found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _organization = org;
        _totalSites = org.totalSites;
        _totalExpenses = org.totalExpenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Dashboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_organization == null) {
      return const Center(child: Text('No organization data'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Welcome back!',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _organization!.name,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
                fontSize: 24,
                fontWeight: FontWeight.w800,
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
        const SizedBox(height: 20),
        DashboardCard(
          title: 'Storage Used',
          value:
              '${(_organization!.storageUsed / (1024 * 1024)).toStringAsFixed(1)} MB',
          subtitle: 'of ${_organization!.maxStorageMb} MB',
          icon: Icons.cloud_outlined,
          color: Colors.purple,
        ),
        const SizedBox(height: 20),
        _buildSubscriptionCard(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _organization!.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.dashboard,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              DashboardCard(
                title: 'Active Sites',
                value: _totalSites.toString(),
                icon: Icons.location_city,
                color: Colors.blue,
              ),
              DashboardCard(
                title: 'Total Expenses',
                value: _totalExpenses.toString(),
                icon: Icons.receipt_long,
                color: Colors.orange,
              ),
              DashboardCard(
                title: 'Storage Used',
                value:
                    '${(_organization!.storageUsed / (1024 * 1024)).toStringAsFixed(1)} MB',
                subtitle: 'of ${_organization!.maxStorageMb} MB',
                icon: Icons.cloud_outlined,
                color: Colors.purple,
              ),
              DashboardCard(
                title: 'Subscription',
                value: _organization!.subscriptionPlan.toUpperCase(),
                subtitle: '${_organization!.daysLeft} days left',
                icon: Icons.card_membership,
                color: _organization!.showWarning ? Colors.orange : Colors.green,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Subscription Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildSubscriptionCard(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildUsageCard(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    return Card(
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
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildUsageCard() {
    return Card(
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
                  'Usage Limits',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressRow(
              'Sites',
              _totalSites,
              _organization!.maxSites,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildProgressRow(
              'Expenses',
              _totalExpenses,
              _organization!.maxExpenses,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildProgressRow(
              'Storage',
              (_organization!.storageUsed / (1024 * 1024)).round(),
              _organization!.maxStorageMb,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildProgressRow(String label, int current, int max, Color color) {
    final percentage = (current / max).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            Text(
              '$current / $max',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}