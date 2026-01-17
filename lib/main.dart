import 'package:exp_edge/screens/auth/invite_registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'dart:io' show Platform;
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
        debugPrint('📱 Initial deep link: $initialUri');
        // Windows needs more time to initialize the window
        final delay = Platform.isWindows 
            ? const Duration(milliseconds: 2000) 
            : const Duration(milliseconds: 500);
        
        Future.delayed(delay, () {
          _handleDeepLink(initialUri);
        });
      }
    } catch (e) {
      debugPrint('❌ Error getting initial link: $e');
    }

    // Handle incoming links while app is running (warm start)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('📱 Incoming deep link: $uri');
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('❌ Deep link stream error: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('🔗 Processing deep link: $uri');
    debugPrint('   Scheme: ${uri.scheme}');
    debugPrint('   Host: ${uri.host}');
    debugPrint('   Path: ${uri.path}');
    debugPrint('   Segments: ${uri.pathSegments}');

    // Check if it's an invite link
    if (uri.scheme == 'https' &&
        uri.host == 'expedge.mangaloredrives.in' &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments[0] == 'invite') {
      
      // Extract token
      if (uri.pathSegments.length >= 2) {
        final token = uri.pathSegments[1];
        debugPrint('✅ Extracted token: $token');
        
        // Navigate to invite registration
        _navigateToInvite(token);
      } else {
        debugPrint('❌ Invalid invite link format - no token found');
      }
    } else {
      debugPrint('❌ Not a valid invite link');
      debugPrint('   Expected: https://expedge.mangaloredrives.in/invite/{token}');
    }
  }

  void _navigateToInvite(String token) {
    // Use post frame callback to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_navigatorKey.currentState != null) {
        debugPrint('🚀 Navigating to invite screen with token: $token');
        
        // Push the invite screen
        _navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => InviteRegistrationScreen(token: token),
          ),
        );
      } else {
        debugPrint('❌ Navigator not ready yet, retrying...');
        // Retry with exponential backoff for Windows
        _retryNavigation(token, 1);
      }
    });
  }

  void _retryNavigation(String token, int attempt) {
    if (attempt > 5) {
      debugPrint('❌ Failed to navigate after 5 attempts');
      return;
    }

    final delay = Duration(milliseconds: 500 * attempt);
    debugPrint('⏳ Retry attempt $attempt after ${delay.inMilliseconds}ms');
    
    Future.delayed(delay, () {
      if (_navigatorKey.currentState != null) {
        debugPrint('✅ Navigator ready on attempt $attempt');
        _navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => InviteRegistrationScreen(token: token),
          ),
        );
      } else {
        _retryNavigation(token, attempt + 1);
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
    );
  }
}