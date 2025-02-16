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
            _buildDashboardCard("Blood Type", "O+", const Color.fromARGB(255, 241, 17, 159)),
            SizedBox(height: 16),
            _buildDashboardCard("Last Donation", "15 Dec 2024", const Color.fromARGB(255, 123, 146, 153)),
            SizedBox(height: 16),
            _buildDashboardCard("Next Eligible", "15 Mar 2025", const Color.fromARGB(255, 90, 209, 252)),
            SizedBox(height: 16),
            _buildDashboardCard("Total Donations", "8", const Color.fromARGB(255, 88, 235, 108)),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(String title, String value, Color valueColor) {
    return Card(
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
                  style: TextStyle(fontSize: 16, color: const Color.fromARGB(31, 160, 159, 159)),
                ),
                SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valueColor),
                ),
              ],
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: const Color.fromARGB(255, 21, 18, 18),
            ),
          ],
        ),
      ),
    );
  }
}