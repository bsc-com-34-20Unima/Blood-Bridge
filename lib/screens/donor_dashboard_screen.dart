import 'package:bloodbridge/pages/hospitadashboard.dart';
import 'package:bloodbridge/screens/donor_settings.dart';
import 'package:flutter/material.dart';
import '../pages/widgets/profile_summary.dart';
import '../pages/widgets/urgent_requests.dart';
import '../pages/widgets/quick_actions.dart';
import '../pages/widgets/achievements.dart';
import '../pages/widgets/support_section.dart';
import '../pages/widgets/Events.dart';
import '../pages/donor_settings.dart'; // Import settings page

class DonorDashboardScreen extends StatefulWidget {
  const DonorDashboardScreen({super.key});

  @override
  _DonorDashboardScreenState createState() => _DonorDashboardScreenState();
}

class _DonorDashboardScreenState extends State<DonorDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    ProfileSummary(),
    UrgentRequests(),
    QuickActions(),
    Events(),
    Achievements(),
    SupportSection(),
    DonorSettingsScreen(), // Uncommented and properly referenced
  ];

  final List<String> _titles = [
    "Profile & Eligibility",
    "Urgent Requests",
    "Quick Actions",
    "Events",
    "Achievements",
    "Support Section",
    "Settings",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // Notifications action
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              setState(() {
                _currentIndex = 6; // Now valid (index 6 exists)
              });
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
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
            _buildDrawerItem(0, Icons.dashboard, "Profile & Eligibility"),
            _buildDrawerItem(1, Icons.warning, "Urgent Requests"),
            _buildDrawerItem(2, Icons.flash_on, "Quick Actions"),
            _buildDrawerItem(3, Icons.event_available, "Events"),
            _buildDrawerItem(4, Icons.emoji_events, "Achievements"),
            _buildDrawerItem(5, Icons.support, "Support Section"),
            _buildDrawerItem(6, Icons.settings, "Settings"),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout"),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages, // Uses all 7 pages safely
      ),
    );
  }

  // Helper method to reduce duplicate drawer code
  ListTile _buildDrawerItem(int index, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.red),
      title: Text(title),
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        Navigator.pop(context);
      },
    );
  }
}