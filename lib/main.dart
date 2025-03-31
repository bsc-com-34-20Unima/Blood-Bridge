import 'package:bloodbridge/pages/DashboardPages/BloodInventory.dart';
import 'package:bloodbridge/pages/DashboardPages/BloodRequests.dart';
import 'package:bloodbridge/pages/DashboardPages/DashboardPage.dart';
import 'package:bloodbridge/pages/DashboardPages/Donors.dart';
import 'package:bloodbridge/pages/DashboardPages/Events.dart';
import 'package:bloodbridge/pages/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'utils/api_service.dart';  // <-- Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // Firebase is initialized before app starts
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); // Initialize Firebase

  final ApiService apiService = ApiService();  // <-- Create an instance of ApiService
  apiService.testConnection();  // <-- Test the connection on app startup

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
      routes: {
        '/dashboard': (context) => DashboardPage(),
        '/bloodInventory': (context) => BloodInventoryPage(),
        '/donors': (context) => DonorsPage(),
        '/requests': (context) => BloodRequests(),
        '/events': (context) => EventsPage(),
      },
    );
  }
}