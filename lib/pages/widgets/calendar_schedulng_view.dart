import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarSchedulingView extends StatefulWidget {
  const CalendarSchedulingView({super.key});

  @override
  _CalendarSchedulingViewState createState() => _CalendarSchedulingViewState();
}

class _CalendarSchedulingViewState extends State<CalendarSchedulingView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TimeOfDay? _selectedTime;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
            ),
          ),
          SizedBox(height: 20),
          if (_selectedDay != null) ...[
            Text(
              'Select Time',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                '9:00 AM',
                '10:00 AM',
                '11:00 AM',
                '2:00 PM',
                '3:00 PM',
                '4:00 PM',
              ].map((time) => TimeSlotButton(
                time: time,
                isSelected: _selectedTime?.format(context) == time,
                onTap: () {
                  setState(() {
                    _selectedTime = TimeOfDay(
                      hour: int.parse(time.split(':')[0]) + 
                        (time.contains('PM') ? 12 : 0),
                      minute: 0,
                    );
                  });
                },
              )).toList(),
            ),
            SizedBox(height: 20),
            if (_selectedTime != null)
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement appointment booking logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Appointment scheduled successfully!')),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text('Schedule Appointment'),
              ),
          ],
        ],
      ),
    );
  }
}

class TimeSlotButton extends StatelessWidget {
  final String time;
  final bool isSelected;
  final VoidCallback onTap;

  const TimeSlotButton({
    super.key,
    required this.time,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : Colors.black87, backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
      ),
      child: Text(time),
    );
  }
}