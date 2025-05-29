import 'package:bloodbridge/pages/DashboardPages/BloodInventory.dart';
import 'package:bloodbridge/pages/DashboardPages/BloodRequests.dart';
import 'package:bloodbridge/pages/DashboardPages/DashboardPage.dart';
import 'package:bloodbridge/pages/DashboardPages/Donors.dart';
import 'package:bloodbridge/pages/DashboardPages/Events.dart';
import 'package:bloodbridge/pages/forgetpassword.dart';
import 'package:bloodbridge/pages/login.dart';
import 'package:bloodbridge/pages/widgets/deep_link_handler.dart';
import 'package:bloodbridge/pages/widgets/reset_password.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

void main() async {
  // Ensure Flutter is initialized before using platform channels
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Set up deep link handling after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupDeepLinks();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DeepLinkHandler.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Update deep link context when app resumes
    if (state == AppLifecycleState.resumed) {
      final context = _navigatorKey.currentContext;
      if (context != null) {
        DeepLinkHandler.updateContext(context);
      }
    }
  }

  Future<void> _setupDeepLinks() async {
    try {
      final context = _navigatorKey.currentContext;
      if (context != null) {
        await DeepLinkHandler.setupDeepLinks(context);
        developer.log('Deep links initialized successfully');
      } else {
        developer.log('Navigator context not available for deep link setup');
        // Retry after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          final retryContext = _navigatorKey.currentContext;
          if (retryContext != null) {
            DeepLinkHandler.setupDeepLinks(retryContext);
          }
        });
      }
    } catch (e) {
      developer.log('Error setting up deep links: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BloodBridge',
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        iconTheme: const IconThemeData(color: Colors.white),
        primaryColor: Colors.red,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          primary: Colors.red,
        ),
        // Add app bar theme for consistency
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/bloodInventory': (context) => BloodInventoryPage(),
        '/donors': (context) => const DonorsPage(),
        '/requests': (context) => const BloodRequests(),
        '/events': (context) => const EventsPage(),
        // Add more routes as needed
      },
      // Handle dynamic routes and deep links
      onGenerateRoute: (settings) {
        developer.log('Generating route for: ${settings.name}');
        
        // Handle reset password route with token
        if (settings.name?.startsWith('/reset-password') == true) {
          // Extract token from route name or arguments
          String? token;
          
          if (settings.arguments != null) {
            // Token passed as arguments
            final args = settings.arguments as Map<String, dynamic>;
            token = args['token'] as String?;
          } else if (settings.name!.contains('?token=')) {
            // Token in URL query parameters
            final uri = Uri.parse(settings.name!);
            token = uri.queryParameters['token'];
          }
          
          if (token != null && token.isNotEmpty) {
            developer.log('Creating reset password route with token: ${token.substring(0, 8)}...');
            return MaterialPageRoute(
              builder: (context) => ResetPasswordPage(token: token!),
              settings: RouteSettings(name: '/reset-password', arguments: {'token': token}),
            );
          } else {
            developer.log('No token found for reset password route');
            return MaterialPageRoute(
              builder: (context) => const ForgotPasswordPage(),
            );
          }
        }
        
        // Handle other dynamic routes here if needed
        
        // Return null to let the system handle unknown routes
        return null;
      },
      // Handle unknown routes
      onUnknownRoute: (settings) {
        developer.log('Unknown route: ${settings.name}');
        return MaterialPageRoute(
          builder: (context) => const UnknownRoutePage(),
        );
      },
      // Global navigation observer for debugging
      navigatorObservers: [
        if (const bool.fromEnvironment('dart.vm.product') == false)
          NavigationLogger(),
      ],
    );
  }
}

// Debug navigation observer - only in debug mode
class NavigationLogger extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    developer.log('Navigated to: ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    developer.log('Replaced route: ${oldRoute?.settings.name} with ${newRoute?.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    developer.log('Popped route: ${route.settings.name}');
  }
}

// Page to show when an unknown route is accessed
class UnknownRoutePage extends StatelessWidget {
  const UnknownRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 100,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Text(
              'Page Not Found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'The page you are looking for does not exist.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // Go back to login/home
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
              ),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }
}