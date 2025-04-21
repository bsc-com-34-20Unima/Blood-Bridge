import 'package:bloodbridge/pages/Settings/changepassword.dart';
import 'package:bloodbridge/pages/Settings/editprofile.dart';
import 'package:bloodbridge/pages/login.dart';
import 'package:bloodbridge/services/auth_service.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _receiveNotifications = true;
  bool _eventReminders = false;
  final AuthService _authService = AuthService();

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
                  MaterialPageRoute(builder: (context) => EditProfilePage()),
                );
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
                  MaterialPageRoute(builder: (context) => ChangePasswordPage()),
                );
              },
            ),

            const Divider(),

            // Notifications Section
            const Text(
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
              },
            ),

            const Divider(),

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

  void _showDeleteAccountDialog(BuildContext context) {
    bool _isDeleting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Delete Account"),
              content: const Text(
                  "Are you sure you want to delete your account? This action cannot be undone."),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: _isDeleting ? null : () {
                    Navigator.pop(context);
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: _isDeleting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Delete",
                          style: TextStyle(color: Colors.white),
                        ),
                  onPressed: _isDeleting
                      ? null
                      : () async {
                          setState(() {
                            _isDeleting = true;
                          });

                          try {
                            await _authService.deleteAccount();
                            
                            // Close the dialog and navigate to login screen
                            if (context.mounted) {
                              Navigator.pop(context); // Close dialog
                              
                              // Navigate to login screen and clear navigation stack
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                                (route) => false,
                              );
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Account deleted successfully')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setState(() {
                                _isDeleting = false;
                              });
                              
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to delete account: ${e.toString()}')),
                              );
                            }
                          }
                        },
                ),
              ],
            );
          }
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
              child: const Text("Logout"),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await _authService.logout();
        navigator.pop(); // Close loading dialog
        
        // Navigate to login screen and clear navigation stack
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        navigator.pop(); // Close loading dialog
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Logout failed: ${e.toString()}')),
        );
      }
    }
  }
}
