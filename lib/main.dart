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

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Set up deep link handling after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkHandler.setupDeepLinks(_navigatorKey.currentContext!);
    });
  }

  @override
  void dispose() {
    DeepLinkHandler.dispose();
    super.dispose();
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
      ),
      home: const LoginScreen(),
      routes: {
        '/': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/bloodInventory': (context) => BloodInventoryPage(),
        '/donors': (context) => const DonorsPage(),
        '/requests': (context) => const BloodRequests(),
        '/events': (context) => const EventsPage(),
        // Add the donor settings route
        //'/donor-settings': (context) => const DonorSettingsScreen(),
      },
      // Enable onGenerateRoute for dynamic routes like reset-password with token
      onGenerateRoute: (settings) {
        // Handle routes that need parameters
        if (settings.name == '/reset-password' && settings.arguments != null) {
          final args = settings.arguments as Map<String, dynamic>;
          final token = args['token'] as String;
          return MaterialPageRoute(
            builder: (context) => ResetPasswordPage(token: token),
          );
        }
        return null;
      },
    );
  }
}