import 'package:flutter/material.dart';

class Achievements extends StatelessWidget {
  final int donations; // Number of donations by the donor

  const Achievements({super.key, required this.donations});

  @override
  Widget build(BuildContext context) {
    // Determine achievement level based on donations
    String level;
    double progress;
    Color progressColor;

    if (donations >= 20) {
      level = 'Platinum Donor';
      progress = 1.0;
      progressColor = Colors.blueGrey;
    } else if (donations >= 10) {
      level = 'Gold Donor';
      progress = donations / 20;
      progressColor = Colors.amber;
    } else if (donations >= 5) {
      level = 'Silver Donor';
      progress = donations / 20;
      progressColor = Colors.grey;
    } else {
      level = 'Regular Donor';
      progress = donations / 20;
      progressColor = Colors.brown;
    }

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: progressColor.withOpacity(0.3),
                          child: Icon(
                            Icons.emoji_events,
                            color: progressColor,
                          ),
                        ),
                        SizedBox(width: 16.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              level,
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "$donations donations",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 16.0),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
