// lib/widgets/quick_actions.dart
import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            _buildActionButton(
              context,
              Icons.calendar_today,
              'Schedule Donation',
              Colors.blue,
            ),
            SizedBox(height: 8),
            _buildActionButton(
              context,
              Icons.location_on,
              'Find Donation Centers',
              Colors.green,
            ),
            SizedBox(height: 8),
            _buildActionButton(
              context,
              Icons.emoji_events,
              'View Achievements',
              Colors.amber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Material(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: color),
              SizedBox(width: 16),
              Expanded(child: Text(label)),
              Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}