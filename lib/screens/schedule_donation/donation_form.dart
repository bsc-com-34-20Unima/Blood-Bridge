// lib/screens/schedule_donation/donation_form.dart
import 'package:flutter/material.dart';

class DonationForm extends StatefulWidget {
  @override
  _DonationFormState createState() => _DonationFormState();
}

class _DonationFormState extends State<DonationForm> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? selectedCenter;
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Date & Time',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    leading: Icon(Icons.calendar_today),
                    title: Text(selectedDate?.toString() ?? 'Select Date'),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 30)),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.access_time),
                    title: Text(selectedTime?.format(context) ?? 'Select Time'),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() => selectedTime = time);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement donation scheduling
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Donation scheduled successfully!')),
              );
              Navigator.pop(context);
            },
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Schedule Donation'),
            ),
          ),
        ],
      ),
    );
  }
}