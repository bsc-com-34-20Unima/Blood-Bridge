import 'package:flutter/material.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile"),
        titleTextStyle: TextStyle(color: Colors.white),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade300,
              child: Icon(Icons.person, size: 50),
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Save profile changes
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}
