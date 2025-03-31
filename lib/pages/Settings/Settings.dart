import 'package:bloodbridge/pages/Settings/changepassword.dart';
import 'package:bloodbridge/pages/Settings/editprofile.dart';
import 'package:flutter/material.dart';
import 'package:bloodbridge/services/auth_service.dart';
import 'package:bloodbridge/pages/login.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Settings",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Account Section
            Text(
              "Account Settings",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.red),
              title: Text("Edit Profile"),
              subtitle: Text("Update your name, email, and profile picture"),
              trailing: Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfilePage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.lock, color: Colors.red),
              title: Text("Change Password"),
              subtitle: Text("Update your account password"),
              trailing: Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChangePasswordPage()));
              },
            ),

            Divider(),

            // Notifications Section
            Text(
              "Notifications",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SwitchListTile(
              activeColor: Colors.red,
              title: Text("Receive Notifications"),
              subtitle: Text("Enable or disable all notifications"),
              value: true,
              onChanged: (bool value) {
                // Toggle notifications setting
              },
            ),
            SwitchListTile(
              activeColor: Colors.red,
              title: Text("Event Reminders"),
              subtitle: Text("Get reminders for upcoming events"),
              value: false,
              onChanged: (bool value) {
                // Toggle event reminders setting
              },
            ),

            Divider(),

            // Privacy Section
            Text(
              "Privacy",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            ListTile(
              leading: Icon(Icons.privacy_tip, color: Colors.red),
              title: Text("Privacy Policy"),
              trailing: Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                // Navigate to Privacy Policy Page
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.red),
              title: Text("Delete Account"),
              trailing: Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                _showDeleteAccountDialog(context);
              },
            ),

            Divider(),

            // Logout Section
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text("Logout"),
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Account"),
          content: Text(
              "Are you sure you want to delete your account? This action cannot be undone."),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text("Delete"),
              onPressed: () {
                // Handle account deletion
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Logout"),
          content: Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text("Logout"),
              onPressed: () async {
                try {
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => Center(child: CircularProgressIndicator()),
                  );
                  
                  // Perform logout
                  await AuthService().signOut();
                  
                  // Close all dialogs
                  Navigator.of(context, rootNavigator: true).pop();
                  Navigator.of(context, rootNavigator: true).pop();
                  
                  // Navigate to LoginScreen and clear stack
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
                  );
                } catch (e) {
                  // Close loading indicator
                  Navigator.of(context, rootNavigator: true).pop();
                  
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logout failed: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}