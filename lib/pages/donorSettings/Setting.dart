import 'package:bloodbridge/pages/donorSettings/changepasswords.dart';
import 'package:bloodbridge/pages/donorSettings/editprofiles.dart';
import 'package:bloodbridge/pages/login.dart';
import 'package:bloodbridge/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _receiveNotifications = true;
  bool _eventReminders = false;
  final AuthService _authService = AuthService();
  String _donorId = '';
  String _currentName = '';
  String _currentEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _donorId = prefs.getString('donorId') ?? '';
        _currentName = prefs.getString('donorName') ?? '';
        _currentEmail = prefs.getString('donorEmail') ?? '';
      });
    } catch (e) {
      _showErrorMessage(context, "Failed to load user data: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Account Section
            const Text(
              "Account Settings",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.red),
              title: const Text("Edit Profile"),
              subtitle: const Text("Update your name, email, and profile picture"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(
                      donorId: _donorId,
                      currentName: _currentName,
                      currentEmail: _currentEmail,
                    ),
                  ),
                ).then((_) => _loadUserData()); // Refresh user data when returning
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock, color: Colors.red),
              title: const Text("Change Password"),
              subtitle: const Text("Update your account password"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangePasswordPage(donorId: _donorId),
                  ),
                ).then((_) {
                  // Optionally handle state after password change
                });
              },
            ),

            const Divider(),

            // Notifications Section
            /*const Text(
              "Notifications",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SwitchListTile(
              activeColor: Colors.red,
              title: const Text("Receive Notifications"),
              subtitle: const Text("Enable or disable all notifications"),
              value: _receiveNotifications,
              onChanged: (bool value) {
                setState(() {
                  _receiveNotifications = value;
                });
                _saveNotificationSettings();
              },
            ),
            SwitchListTile(
              activeColor: Colors.red,
              title: const Text("Event Reminders"),
              subtitle: const Text("Get reminders for upcoming events"),
              value: _eventReminders,
              onChanged: (bool value) {
                setState(() {
                  _eventReminders = value;
                });
                _saveNotificationSettings();
              },
            ),

            const Divider(),*/

            // Privacy Section
            const Text(
              "Privacy",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip, color: Colors.red),
              title: const Text("Privacy Policy"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                // Navigate to Privacy Policy Page
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text("Delete Account"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                _showDeleteAccountDialog(context);
              },
            ),

            const Divider(),

            // Logout Section
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout"),
              onTap: () {
                _showLogoutConfirmationDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('receiveNotifications', _receiveNotifications);
      await prefs.setBool('eventReminders', _eventReminders);
      
      // If you have an API endpoint to save these settings on the server
      // await _authService.updateNotificationSettings(
      //   _donorId, 
      //   _receiveNotifications,
      //   _eventReminders
      // );
    } catch (e) {
      _showErrorMessage(context, "Failed to save notification settings: ${e.toString()}");
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    TextEditingController passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Account"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "This action cannot be undone. To confirm deletion, please enter your password:",
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Password",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                "Delete Account",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                if (passwordController.text.isEmpty) {
                  _showErrorMessage(context, "Please enter your password to confirm");
                  return;
                }
                
                // Show loading indicator
                Navigator.pop(context); // Close the dialog
                _showLoadingDialog(context);
                
                try {
                  final result = await _authService.deleteAccount(
                    donorId: _donorId,
                    password: passwordController.text,
                  );
                  
                  Navigator.pop(context); // Close loading dialog
                  
                  // Clear all stored credentials
                  await _clearAllUserData();
                  
                  _showSuccessMessage(context, "Account deleted successfully");
                  
                  // Navigate to login screen and clear navigation stack
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                } catch (e) {
                  Navigator.pop(context); // Close loading dialog
                  _showErrorMessage(context, "Failed to delete account: ${e.toString()}");
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context, false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      _showLoadingDialog(context);

      try {
        await _authService.logout();
        await _clearAllUserData();
        
        Navigator.pop(context); // Close loading dialog
        
        // Navigate to login screen and clear navigation stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        Navigator.pop(context); // Close loading dialog
        _showErrorMessage(context, 'Logout failed: ${e.toString()}');
      }
    }
  }

  Future<void> _clearAllUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint("Error clearing user data: ${e.toString()}");
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Colors.red,
        ),
      ),
    );
  }

  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}