// lib/widgets/quick_actions.dart
import 'package:bloodbridge/pages/widgets/achievements.dart';
import 'package:bloodbridge/screens/donation_centers/donation_centers_screen.dart';
import 'package:bloodbridge/screens/schedule_donation/schedule_donation_screen.dart';
import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildDashboardCard(
            context,
            Icons.calendar_today,
            'Schedule Donation',
            'Plan your next blood donation',
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScheduleDonationScreen(),
              ),
            ),
          ),
          SizedBox(height: 16),
          
          SizedBox(height: 16),
          _buildDashboardCard(
            context,
            Icons.emoji_events,
            'View Achievements',
            'Track your donation milestones',
            Colors.amber,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Achievements(donations:0,),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  Spacer(),
                  Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}