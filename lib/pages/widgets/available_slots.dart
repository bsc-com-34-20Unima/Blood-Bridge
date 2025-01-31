import 'package:flutter/material.dart';

class AvailableSlots extends StatelessWidget {
  const AvailableSlots({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SlotCard(
              time: '2:00 PM',
              location: 'City General Hospital',
              date: 'Today',
            ),
            SizedBox(height: 16.0),
            SlotCard(
              time: '10:00 AM',
              location: 'Memorial Medical Center',
              date: 'Tomorrow',
            ),
          ],
        ),
      ),
    );
  }
}

class SlotCard extends StatelessWidget {
  final String time;
  final String location;
  final String date;

  const SlotCard({super.key, 
    required this.time,
    required this.location,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              location,
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              date,
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
