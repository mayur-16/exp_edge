
import 'package:flutter/material.dart';

/// Breakpoints for responsive design
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Helper class to determine screen size
class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < ResponsiveBreakpoints.mobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.mobile &&
      MediaQuery.of(context).size.width < ResponsiveBreakpoints.desktop;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.desktop;

  static bool isLargeScreen(BuildContext context) =>
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.tablet;
}

/// Responsive layout wrapper that builds different widgets based on screen size
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveBreakpoints.desktop) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= ResponsiveBreakpoints.mobile) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// Grid configuration for responsive layouts
class ResponsiveGrid {
  static int getCrossAxisCount(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) return 3;
    if (ResponsiveHelper.isTablet(context)) return 2;
    return 1;
  }

  static double getCardWidth(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) return 400;
    if (ResponsiveHelper.isTablet(context)) return 350;
    return double.infinity;
  }

  static EdgeInsets getPadding(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      return const EdgeInsets.all(24);
    }
    return const EdgeInsets.all(16);
  }
}