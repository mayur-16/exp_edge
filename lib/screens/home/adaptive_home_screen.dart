// lib/screens/home/adaptive_home_screen.dart

import 'package:exp_edge/screens/home/adaptive_dashboard_tab.dart';
import 'package:flutter/material.dart';
import '../../core/responsive/adaptive_scaffold.dart';
import '../../services/auth_service.dart';
import '../../models/organization.dart';
import '../sites/sites_screen.dart';
import '../vendors/vendors_screen.dart';
import '../expenses/expenses_screen.dart';
import '../profile/profile_screen.dart';
import 'widgets/subscription_warning_dialog.dart';
import 'dashboard_tab.dart';

class AdaptiveHomeScreen extends StatefulWidget {
  const AdaptiveHomeScreen({super.key});

  @override
  State<AdaptiveHomeScreen> createState() => _AdaptiveHomeScreenState();
}

class _AdaptiveHomeScreenState extends State<AdaptiveHomeScreen> {
  int _selectedIndex = 0;
  Organization? _organization;
  bool _hasShownWarning = false;

  @override
  void initState() {
    super.initState();
    _loadOrganization();
  }

  Future<void> _loadOrganization() async {
    final org = await AuthService().getUserOrganization();
    if (mounted) {
      setState(() => _organization = org);

      if (org != null && org.showWarning && !_hasShownWarning) {
        _hasShownWarning = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (_) => SubscriptionWarningDialog(
              daysLeft: org.daysLeft,
              onDismiss: () => setState(() => _hasShownWarning = false),
            ),
          );
        });
      }
    }
  }

  final List<AdaptiveNavItem> _destinations = const [
    AdaptiveNavItem(
      label: 'Sites',
      icon: Icons.location_city_outlined,
      selectedIcon: Icons.location_city,
      screen: SitesScreen(),
    ),
    AdaptiveNavItem(
      label: 'Expenses',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      screen: ExpensesScreen(),
    ),
    AdaptiveNavItem(
      label: 'Vendors',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      screen: VendorsScreen(),
    ),
    AdaptiveNavItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      screen: AdaptiveDashboardTab(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Exp Edge',
      destinations: _destinations,
      currentIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      actions: [
        if (_organization != null && _organization!.showWarning)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_organization!.daysLeft} days left',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
          tooltip: 'Profile',
        ),
      ],
    );
  }
}