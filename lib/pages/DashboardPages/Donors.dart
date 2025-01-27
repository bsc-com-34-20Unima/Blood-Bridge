import 'package:flutter/material.dart';

class DonorsPage extends StatelessWidget {
  final List<Map<String, String>> donors = [
    {"name": "John Doe", "bloodGroup": "O+", "contact": "123-456-7890", "lastDonation": "2024-12-01"},
    {"name": "Jane Smith", "bloodGroup": "A-", "contact": "987-654-3210", "lastDonation": "2025-01-15"},
    {"name": "James Brown", "bloodGroup": "B+", "contact": "555-444-3333", "lastDonation": "2024-11-10"},
    {"name": "Emily White", "bloodGroup": "AB-", "contact": "444-333-2222", "lastDonation": "2025-01-05"},
    {"name": "Michael Green", "bloodGroup": "O-", "contact": "111-222-3333", "lastDonation": "2024-12-25"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    );
  }
}
