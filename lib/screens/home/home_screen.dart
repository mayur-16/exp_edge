import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/organization.dart';
import '../sites/sites_screen.dart';
import '../vendors/vendors_screen.dart';
import '../expenses/expenses_screen.dart';
import '../profile/profile_screen.dart';
import 'widgets/subscription_warning_dialog.dart';
import 'dashboard_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      
      // Show warning if subscription expiring soon
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

  final List<Widget> _screens = [
    const DashboardTab(),
    const SitesScreen(),
    const ExpensesScreen(),
    const VendorsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exp Edge'),
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
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_city_outlined),
            selectedIcon: Icon(Icons.location_city),
            label: 'Sites',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Vendors',
          ),
        ],
      ),
    );
  }
}