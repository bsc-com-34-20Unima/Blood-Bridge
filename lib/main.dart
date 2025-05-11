import 'package:bloodbridge/pages/widgets/token_validation_page.dart';
import 'package:flutter/material.dart';
import 'package:bloodbridge/pages/DashboardPages/BloodInventory.dart';
import 'package:bloodbridge/pages/DashboardPages/BloodRequests.dart';
import 'package:bloodbridge/pages/DashboardPages/DashboardPage.dart';
import 'package:bloodbridge/pages/DashboardPages/Donors.dart';
import 'package:bloodbridge/pages/DashboardPages/Events.dart';
import 'package:bloodbridge/pages/forgetpassword.dart';
import 'package:bloodbridge/pages/login.dart';
import 'package:bloodbridge/pages/widgets/reset_password_page.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';

bool _initialUriIsHandled = false;

void main() async {
  // Make sure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Uri? _initialUri;
  StreamSubscription? _sub;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _handleIncomingLinks();
    _handleInitialUri();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // Handle incoming links when app is already running
  void _handleIncomingLinks() {
    _sub = uriLinkStream.listen((Uri? uri) {
      if (!mounted) return;
      _handleDeepLink(uri);
    }, onError: (Object err) {
      debugPrint('Error handling incoming links: $err');
    });
  }

  // Handle initial URI (when app is started from a link)
  Future<void> _handleInitialUri() async {
    if (!_initialUriIsHandled) {
      _initialUriIsHandled = true;
      try {
        final uri = await getInitialUri();
        if (uri != null) {
          _initialUri = uri;
          // Handle the initial URI after the app is built
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleDeepLink(uri);
          });
        }
      } catch (e) {
        debugPrint('Error getting initial URI: $e');
      }
    }
  }

  // Process the deep link and navigate accordingly
  void _handleDeepLink(Uri? uri) {
    if (uri == null) return;
    
    debugPrint('Got URI: $uri');
    
    if (uri.path == '/reset-password' || uri.path == 'reset-password') {
      final token = uri.queryParameters['token'];
      if (token != null) {
        _navigatorKey.currentState?.pushNamed('/token-validation', arguments: token);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      home: LoginScreen(),
      routes: {
        '/dashboard': (context) => DashboardPage(),
        '/bloodInventory': (context) => BloodInventoryPage(),
        '/donors': (context) => DonorsPage(),
        '/requests': (context) => BloodRequests(),
        '/events': (context) => EventsPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/login': (context) => LoginScreen(),
        '/token-validation': (context) => TokenValidationPage(
          token: ModalRoute.of(context)?.settings.arguments as String,
        ),
      },
      onGenerateRoute: (settings) {
        // Handle deep links and normal routes
        if (settings.name?.contains('reset-password') == true) {
          // Extract token from URL query parameters
          final uri = Uri.parse(settings.name!);
          final token = uri.queryParameters['token'];
          
          if (token != null) {
            return MaterialPageRoute(
              builder: (context) => TokenValidationPage(token: token),
            );
          }
        }
        // Handle other routes as needed
        return null;
      },
    );
  }
}