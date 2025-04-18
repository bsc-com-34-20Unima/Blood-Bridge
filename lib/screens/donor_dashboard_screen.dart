import 'package:flutter/material.dart';
import '../pages/widgets/profile_summary.dart';
import '../pages/widgets/urgent_requests.dart';
import '../pages/widgets/quick_actions.dart';
import '../pages/widgets/achievements.dart';
import '../pages/widgets/support_section.dart';
import '../pages/widgets/Events.dart';
import '../pages/Settings/Settings.dart';

class DonorDashboardScreen extends StatefulWidget {
  const DonorDashboardScreen({super.key});

  @override
  _DonorDashboardScreenState createState() => _DonorDashboardScreenState();
}

class _DonorDashboardScreenState extends State<DonorDashboardScreen> {
  int _currentIndex = 0;

  final List _pages = [
    ProfileSummary(),
    UrgentRequests(),
    QuickActions(),
    Events(),
    Achievements(),
    SupportSection(),
  ];

  final List _titles = [
    "Profile & Eligibility",
    "Urgent Requests",
    "Quick Actions",
    "Events",
    "Achievements",
    "Support Section",
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
              // Notifications action
            },
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // Navigate to settings page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
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
                    Icon(Icons.volunteer_activism, size: 50, color: Colors.white),
                    SizedBox(height: 10),
                    Text(
                      "Donor Dashboard",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard, color: Colors.red),
              title: Text("Profile & Eligibility"),
              onTap: () {
                setState(() {
                  _currentIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.warning, color: Colors.red),
              title: Text("Urgent Requests"),
              onTap: () {
                setState(() {
                  _currentIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.flash_on, color: Colors.red),
              title: Text("Quick Actions"),
              onTap: () {
                setState(() {
                  _currentIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.event_available, color: Colors.red),
              title: Text("Events"),
              onTap: () {
                setState(() {
                  _currentIndex = 3;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.emoji_events, color: Colors.red),
              title: Text("Achievements"),
              onTap: () {
                setState(() {
                  _currentIndex = 4;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.support, color: Colors.red),
              title: Text("Support Section"),
              onTap: () {
                setState(() {
                  _currentIndex = 5;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _pages[_currentIndex],
    );
  }
}
