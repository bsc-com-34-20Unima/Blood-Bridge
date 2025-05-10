
import 'package:bloodbridge/pages/widgets/blood_bridge_appbar.dart';
import 'package:bloodbridge/pages/widgets/notification_page.dart';
import 'package:bloodbridge/pages/widgets/notification_service.dart';
// Removed import for recent_notification_widget.dart as we don't need it anymore
import 'package:flutter/material.dart';
import 'package:bloodbridge/pages/widgets/profile_summary.dart';
import 'package:bloodbridge/pages/widgets/urgent_requests.dart';
import 'package:bloodbridge/pages/widgets/quick_actions.dart';
import 'package:bloodbridge/pages/widgets/achievements.dart';
import 'package:bloodbridge/pages/widgets/support_section.dart';
import 'package:bloodbridge/pages/widgets/Events.dart';
import 'package:bloodbridge/pages/Settings/Settings.dart';
class DonorDashboardScreen extends StatefulWidget {
  const DonorDashboardScreen({super.key});

  @override
  _DonorDashboardScreenState createState() => _DonorDashboardScreenState();
}

class _DonorDashboardScreenState extends State<DonorDashboardScreen> {
  int _currentIndex = 0;
  final NotificationService _notificationService = NotificationService();

  final List<Widget> _pages = [

    const ProfileSummary(),
    const UrgentRequests(),
    const QuickActions(),
    const Events(),
    const Achievements(),
    const SupportSection(),
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
  void initState() {
    super.initState();
    // Refresh notifications when the dashboard is first loaded
    _refreshNotifications();
  }

  // Method to refresh notifications
  Future<void> _refreshNotifications() async {
    // This will trigger a refresh of notification data in the NotificationService
    await _notificationService.getUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: BloodBridgeAppBar(
        title: _titles[_currentIndex],
        showNotificationIcon: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // Navigate to settings page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              ).then((_) {
                // Refresh notifications when returning from settings
                _refreshNotifications();
              });
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: _refreshNotifications,
        color: Colors.red,
        child: _pages[_currentIndex], // Display only the current page without wrapping in ListView
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.red),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
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
            leading: const Icon(Icons.dashboard, color: Colors.red),
            title: const Text("Profile & Eligibility"),
            onTap: () {
              setState(() {
                _currentIndex = 0;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.warning, color: Colors.red),
            title: const Text("Urgent Requests"),
            onTap: () {
              setState(() {
                _currentIndex = 1;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.flash_on, color: Colors.red),
            title: const Text("Quick Actions"),
            onTap: () {
              setState(() {
                _currentIndex = 2;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.event_available, color: Colors.red),
            title: const Text("Events"),
            onTap: () {
              setState(() {
                _currentIndex = 3;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events, color: Colors.red),
            title: const Text("Achievements"),
            onTap: () {
              setState(() {
                _currentIndex = 4;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.support, color: Colors.red),
            title: const Text("Support Section"),
            onTap: () {
              setState(() {
                _currentIndex = 5;
              });
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.red),
            title: const Text("Notifications"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationPage()),
              ).then((_) {
                // Refresh notifications when returning from the notifications page
                _refreshNotifications();
              });
            },
          ),
        ],
      ),
    );
  }
}