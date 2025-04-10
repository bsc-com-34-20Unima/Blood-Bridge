import 'package:bloodbridge/pages/DashboardPages/BloodInventory.dart';
import 'package:bloodbridge/pages/DashboardPages/DashboardPage.dart';
import 'package:bloodbridge/pages/DashboardPages/Donors.dart';
import 'package:bloodbridge/pages/DashboardPages/Events.dart';
import 'package:bloodbridge/pages/Settings/Alerts.dart';
import 'package:bloodbridge/pages/Settings/Settings.dart';
import 'package:flutter/material.dart';
import 'package:bloodbridge/pages/DashboardPages/BloodRequests.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hospital Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.red),
      home: HospitalDashboard(),
    );
  }
}

class HospitalDashboard extends StatefulWidget {
  const HospitalDashboard({super.key});

  @override
  _HospitalDashboardState createState() => _HospitalDashboardState();
}

class _HospitalDashboardState extends State<HospitalDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    DashboardPage(),
    BloodInventoryPage(),
    DonorsPage(),
    BloodRequests(),
    EventsPage()
  ];

  final List<String> _titles = [
    "Dashboard",
    "Blood Inventory",
    "Donors",
    "Requests",
    "Events",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          _titles[_currentIndex],
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => AlertPage()));
            },
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // Settings action
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => SettingsPage()));
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.red),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_hospital, size: 50, color: Colors.white),
                    SizedBox(height: 10),
                    Text(
                      "City General Hospital",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard, color: Colors.red),
              title: Text("Dashboard"),
              onTap: () {
                setState(() {
                  _currentIndex = 0;
                });
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: Icon(Icons.bloodtype, color: Colors.red),
              title: Text("Blood Inventory"),
              onTap: () {
                setState(() {
                  _currentIndex = 1;
                });
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: Icon(Icons.people, color: Colors.red),
              title: Text("Donors"),
              onTap: () {
                setState(() {
                  _currentIndex = 2;
                });
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: Icon(Icons.list, color: Colors.red),
              title: Text("Requests"),
              onTap: () {
                setState(() {
                  _currentIndex = 3;
                });
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: Icon(Icons.event, color: Colors.red),
              title: Text("Events"),
              onTap: () {
                setState(() {
                  _currentIndex = 4;
                });
                Navigator.pop(context); // Close the drawer
              },
            ),
          ],
        ),
      ),
      body: _pages[_currentIndex],
    );
  }
}
