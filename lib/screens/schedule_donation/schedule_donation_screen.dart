// lib/screens/schedule_donation/schedule_donation_screen.dart
import 'package:flutter/material.dart';
import 'donation_form.dart';

class ScheduleDonationScreen extends StatelessWidget {
  const ScheduleDonationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule Donation'),
      ),
      body: DonationForm(),
    );
  }
}