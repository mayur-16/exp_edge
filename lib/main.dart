import 'package:exp_edge/screens/auth/invite_registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'core/config/supabase_config.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  
  runApp(const ProviderScope(child: ExpEdgeApp()));
}

class ExpEdgeApp extends StatefulWidget {
  const ExpEdgeApp({super.key});

  @override
  State<ExpEdgeApp> createState() => _ExpEdgeAppState();
}

class _ExpEdgeAppState extends State<ExpEdgeApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle link that opened the app (cold start)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        print('📱 Initial deep link: $initialUri');
        // Delay to ensure navigation is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleDeepLink(initialUri);
        });
      }
    } catch (e) {
      print('❌ Error getting initial link: $e');
    }

    // Handle incoming links while app is running (warm start)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        print('📱 Incoming deep link: $uri');
        _handleDeepLink(uri);
      },
      onError: (err) {
        print('❌ Deep link stream error: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    print('🔗 Processing deep link: $uri');
    print('   Scheme: ${uri.scheme}');
    print('   Host: ${uri.host}');
    print('   Path: ${uri.path}');
    print('   Segments: ${uri.pathSegments}');

    // Check if it's an invite link
    if (uri.scheme == 'https' &&
        uri.host == 'expedge.mangaloredrives.in' &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments[0] == 'invite') {
      
      // Extract token
      if (uri.pathSegments.length >= 2) {
        final token = uri.pathSegments[1];
        print('✅ Extracted token: $token');
        
        // Navigate to invite registration
        _navigateToInvite(token);
      } else {
        print('❌ Invalid invite link format - no token found');
      }
    } else {
      print('❌ Not a valid invite link');
    }
  }

  void _navigateToInvite(String token) {
    // Use post frame callback to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_navigatorKey.currentState != null) {
        print('🚀 Navigating to invite screen with token: $token');
        
        // Push the invite screen
        _navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => InviteRegistrationScreen(token: token),
          ),
        );
      } else {
        print('❌ Navigator not ready yet');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Exp Edge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      // Remove the named routes - using programmatic navigation instead
    );
  }
}