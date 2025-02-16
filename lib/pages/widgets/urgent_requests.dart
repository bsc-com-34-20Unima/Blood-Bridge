// lib/widgets/urgent_requests.dart
import 'package:flutter/material.dart';

class UrgentRequests extends StatelessWidget {
  const UrgentRequests({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            _buildRequestItem(
              context,
              'City General Hospital',
              'O+',
              '2.5 km',
            ),
            SizedBox(height: 8),
            _buildRequestItem(
              context,
              'Memorial Medical Center',
              'A-',
              '4.2 km',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestItem(
    BuildContext context,
    String hospital,
    String bloodType,
    String distance,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$hospital needs $bloodType',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                Text(
                  '$distance away',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('Respond Now'),
          ),
        ],
      ),
    );
  }
}