// lib/pages/detail_pages/donation_importance.dart
import 'package:flutter/material.dart';

class DonationImportance extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Importance of Blood Donation'),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why Your Donations Matter',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 20),
            _buildImportancePoint(
              'Life-Saving Impact',
              'One donation can save up to three lives.',
            ),
            _buildImportancePoint(
              'Emergency Readiness',
              'Blood banks need regular donations to maintain sufficient supply for emergencies.',
            ),
            _buildImportancePoint(
              'Medical Procedures',
              'Supports various medical procedures, surgeries, and treatments.',
            ),
            _buildImportancePoint(
              'Community Support',
              'Helps patients in your local community receive necessary treatment.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportancePoint(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}