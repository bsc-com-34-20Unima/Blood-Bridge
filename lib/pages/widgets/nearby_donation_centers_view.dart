import 'calendar_schedulng_view.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class NearbyDonationCentersView extends StatelessWidget {
  final Position userLocation;

  const NearbyDonationCentersView({
    super.key,
    required this.userLocation,
  });

  @override
  Widget build(BuildContext context) {
    // Dummy data for demonstration
    final centers = [
      {
        'name': 'City General Hospital',
        'distance': '2.3',
        'address': '123 Medical Center Ave',
        'rating': 4.5,
      },
      {
        'name': 'Community Blood Bank',
        'distance': '3.1',
        'address': '456 Health Street',
        'rating': 4.8,
      },
      {
        'name': 'Regional Medical Center',
        'distance': '4.7',
        'address': '789 Hospital Road',
        'rating': 4.2,
      },
    ];

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: centers.length,
      itemBuilder: (context, index) {
        final center = centers[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            title: Text(
             center as String,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
                Text(center as String),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('${center['distance']} km away'),
                    SizedBox(width: 16),
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    SizedBox(width: 4),
                    Text('${center['rating']}'),
                  ],
                ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () {
                // TODO: Implement navigation to booking screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CalendarSchedulingView(),
                  ),
                );
              },
              child: Text('Book'),
            ),
          ),
        );
      },
    );
  }
}