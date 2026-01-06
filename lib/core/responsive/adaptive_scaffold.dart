
import 'package:flutter/material.dart';
import 'responsive_layout.dart';

/// Navigation destination model
class AdaptiveNavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;

  const AdaptiveNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });
}

/// Adaptive scaffold that switches between bottom nav and side rail
class AdaptiveScaffold extends StatefulWidget {
  final String title;
  final List<AdaptiveNavItem> destinations;
  final List<Widget>? actions;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget? floatingActionButton;

  const AdaptiveScaffold({
    super.key,
    required this.title,
    required this.destinations,
    this.actions,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.floatingActionButton,
  });

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    if (isDesktop) {
      return _buildDesktopLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: widget.actions,
      ),
      body: widget.destinations[widget.currentIndex].screen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.currentIndex,
        onDestinationSelected: widget.onDestinationSelected,
        destinations: widget.destinations
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: item.label,
                ))
            .toList(),
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Side Navigation Rail
          NavigationRail(
            extended: MediaQuery.of(context).size.width > 1400,
            selectedIndex: widget.currentIndex,
            onDestinationSelected: widget.onDestinationSelected,
            labelType: MediaQuery.of(context).size.width > 1400
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  if (MediaQuery.of(context).size.width > 1400)
                    Text(
                      'Exp Edge',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
            destinations: widget.destinations
                .map((item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: Text(item.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top App Bar for Desktop
                Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        if (widget.actions != null) ...widget.actions!,
                      ],
                    ),
                  ),
                ),
                
                // Content
                Expanded(
                  child: widget.destinations[widget.currentIndex].screen,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }
}