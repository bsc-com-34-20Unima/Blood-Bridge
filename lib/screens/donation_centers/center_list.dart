// lib/screens/donation_centers/center_list.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class CenterList extends StatelessWidget {
  final Position position;

  const CenterList({Key? key, required this.position}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Implement API call to fetch nearby centers
    final dummyCenters = [
      {
        'name': 'City Hospital',
        'address': '123 Main St',
        'distance': 2.5,
      },
      {
        'name': 'Red Cross Center',
        'address': '456 Oak Ave',
        'distance': 3.8,
      },
    ];

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: dummyCenters.length,
      itemBuilder: (context, index) {
        final center = dummyCenters[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text(center['name'] as String),
            subtitle: Text(center['address'] as String),
            trailing: Text('${center['distance']} km'),
            onTap: () {
              // TODO: Implement navigation to center details
            },
          ),
        );
      },
    );
  }
}
