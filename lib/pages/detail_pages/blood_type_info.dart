// lib/pages/detail_pages/blood_type_info.dart
import 'package:flutter/material.dart';

class BloodTypeInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blood Type Information'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Blood Type: O+',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 20),
            _buildCompatibilitySection(
              'Can Donate To:',
              ['O+', 'A+', 'B+', 'AB+'],
            ),
            SizedBox(height: 20),
            _buildCompatibilitySection(
              'Can Receive From:',
              ['O+', 'O-'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompatibilitySection(String title, List<String> types) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: types.map((type) => Chip(label: Text(type))).toList(),
        ),
      ],
    );
  }
}
