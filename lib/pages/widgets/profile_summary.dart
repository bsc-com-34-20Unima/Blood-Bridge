// lib/pages/widgets/profile_summary.dart
import 'package:bloodbridge/pages/detail_pages/blood_type_info.dart';
import 'package:bloodbridge/pages/detail_pages/donation_dates.dart';
import 'package:bloodbridge/pages/detail_pages/donation_importance.dart';
import 'package:flutter/material.dart';

class ProfileSummary extends StatelessWidget {
  const ProfileSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDashboardCard(
              context,
              "Blood Type",
              "O+",
              Colors.red,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BloodTypeInfo()),
              ),
            ),
            SizedBox(height: 16),
            _buildDashboardCard(
              context,
              "Last Donation",
              "15 Dec 2024",
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DonationDates(isNextEligible: false)),
              ),
            ),
            SizedBox(height: 16),
            _buildDashboardCard(
              context,
              "Next Eligible",
              "15 Mar 2025",
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DonationDates(isNextEligible: true)),
              ),
            ),
            SizedBox(height: 16),
            _buildDashboardCard(
              context,
              "Total Donations",
              "8",
              Colors.purple,
              () => _showDonationDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    String value,
    Color valueColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDonationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Your Donations"),
          content: Text(
            "You've made 8 donations so far! Would you like to view your achievements?",
          ),
          actions: [
            TextButton(
              child: Text("Not Now"),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DonationImportance()),
                );
              },
            ),
            TextButton(
              child: Text("View Achievements"),
              onPressed: () {
                Navigator.pop(context);
                // Navigate to achievements page
                // You'll need to implement the navigation to your achievements page
              },
            ),
          ],
        );
      },
    );
  }
}