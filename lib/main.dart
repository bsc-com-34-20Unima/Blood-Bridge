import 'package:bloodbridge/pages/DashboardPages/BloodInventory.dart';
import 'package:bloodbridge/pages/DashboardPages/BloodRequests.dart';
import 'package:bloodbridge/pages/DashboardPages/DashboardPage.dart';
import 'package:bloodbridge/pages/DashboardPages/Donors.dart';
import 'package:bloodbridge/pages/DashboardPages/Events.dart';
import 'package:bloodbridge/pages/login.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: LoginPage(),
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

