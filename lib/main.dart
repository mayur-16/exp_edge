
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
    _appLinks = AppLinks();  // Initialize the instance
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    // Handle link that opened the app (initial link)
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    // Handle incoming links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
        });
  }

  void _handleDeepLink(Uri uri) {
    // Only handle HTTPS App Links
    if (uri.scheme == 'https' &&
        uri.host == 'expedge.mangaloredrives.in' &&
        uri.path.startsWith('/invite/')) {
      
      // Extract token from /invite/TOKEN
      if (uri.pathSegments.length >= 2) {
        final token = uri.pathSegments[1];
        
        // Navigate to invite registration screen
        _navigatorKey.currentState?.pushNamed('/invite', arguments: token);
      }
    }
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
      // Make sure you have this route defined somewhere
      routes: {
        '/invite': (context) => InviteRegistrationScreen(
              token: ModalRoute.of(context)!.settings.arguments as String,
            ),
      },
    );
  }
}