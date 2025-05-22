import 'package:bloodbridge/pages/DashboardPages/BloodInventory.dart';
import 'package:bloodbridge/pages/DashboardPages/DashboardPage.dart';
import 'package:bloodbridge/pages/DashboardPages/Donors.dart';
import 'package:bloodbridge/pages/DashboardPages/Events.dart';
import 'package:bloodbridge/pages/DashboardPages/donation_scheduling.dart';
import 'package:bloodbridge/pages/DashboardPages/donation_scheduling.dart';
import 'package:bloodbridge/pages/DashboardPages/hospital_service.dart';
import 'package:bloodbridge/pages/hospitalSettings/Alerts.dart';
import 'package:bloodbridge/pages/hospitalSettings/changepassword.dart';
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
  String _hospitalName = "Loading..."; // Default placeholder
  final HospitalService _hospitalService = HospitalService();

  final List<Widget> _pages = [
    DashboardPage(),
    BloodInventoryPage(),
    DonorsPage(),
    BloodRequests(),
    DonationSchedulePage(),
    EventsPage()
  ];

  final List<String> _titles = [
    "Dashboard",
    "Blood Inventory",
    "Donors",
    "Requests",
    "Donation Scheduling",
    "Events",
  ];

  @override
  void initState() {
    super.initState();
    _fetchHospitalName();
  }
  
  // Method to manually refresh the hospital name
  void _refreshHospitalName() {
    setState(() {
      _hospitalName = "Loading...";
    });
    _fetchHospitalName();
  }

  // Method to fetch hospital name from backend
  Future<void> _fetchHospitalName() async {
    try {
      final hospital = await _hospitalService.getCurrentHospital();
      setState(() {
        _hospitalName = hospital.name;
      });
    } catch (e) {
      setState(() {
        _hospitalName = "Hospital"; // Fallback name
      });
      print('Error fetching hospital name: $e');
    }
  }

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
                  MaterialPageRoute(builder: (context) => UpdateHospitalPage()));
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
                    _hospitalName == "Loading..." 
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Loading...",
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _hospitalName,
                              style: TextStyle(color: Colors.white, fontSize: 18),
                            ),
                            IconButton(
                              icon: Icon(Icons.refresh, color: Colors.white, size: 16),
                              onPressed: _refreshHospitalName,
                              padding: EdgeInsets.only(left: 4),
                              constraints: BoxConstraints(),
                              tooltip: 'Refresh hospital data',
                            ),
                          ],
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
              leading: Icon(Icons.calendar_today, color: Colors.red),
              title: Text("Donation Scheduling"),
              onTap: () {
                setState(() {
                  _currentIndex = 4;
                });
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: Icon(Icons.event, color: Colors.red),
              title: Text("Events"),
              onTap: () {
                setState(() {
                  _currentIndex = 5;
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