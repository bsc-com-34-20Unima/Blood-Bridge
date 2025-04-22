import 'package:bloodbridge/pages/DashboardPages/BloodInventory.dart';
import 'package:bloodbridge/pages/DashboardPages/BloodRequests.dart';
import 'package:bloodbridge/pages/DashboardPages/DashboardPage.dart';
import 'package:bloodbridge/pages/DashboardPages/Donors.dart';
import 'package:bloodbridge/pages/DashboardPages/Events.dart';
import 'package:bloodbridge/pages/login.dart';
import 'package:flutter/material.dart';


void main() async {


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
      },
    );
  }
}