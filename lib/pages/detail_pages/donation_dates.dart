// lib/pages/detail_pages/donation_dates.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class DonationDates extends StatefulWidget {
  final bool isNextEligible;

  const DonationDates({super.key, required this.isNextEligible});

  @override
  _DonationDatesState createState() => _DonationDatesState();
}

class _DonationDatesState extends State<DonationDates> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late DateTime _lastDonationDate;
  late DateTime _nextEligibleDate;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    // Assuming last donation was on Dec 15, 2024
    _lastDonationDate = DateTime(2024, 12, 15);
    // Next eligible date is 3 months after last donation
    _nextEligibleDate = _lastDonationDate.add(Duration(days: 90));
  }

  int _calculateDaysDifference() {
    final now = DateTime.now();
    if (widget.isNextEligible) {
      return _nextEligibleDate.difference(now).inDays;
    } else {
      return now.difference(_lastDonationDate).inDays;
    }
  }

  Color _getDayColor(DateTime day) {
    if (isSameDay(day, _lastDonationDate)) {
      return Colors.red;
    } else if (isSameDay(day, _nextEligibleDate)) {
      return Colors.green;
    } else if (day.isAfter(_lastDonationDate) && day.isBefore(_nextEligibleDate)) {
      return Colors.orange.withOpacity(0.3);
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNextEligible ? 'Next Eligible Date' : 'Last Donation Date'),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            SizedBox(height: 20),
            _buildCalendar(),
            SizedBox(height: 20),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isNextEligible
                  ? 'Days until next eligible donation:'
                  : 'Days since last donation:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '${_calculateDaysDifference()} days',
              style: TextStyle(
                fontSize: 24,
                color: widget.isNextEligible ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              widget.isNextEligible
                  ? 'Next eligible date: ${DateFormat('MMMM d, y').format(_nextEligibleDate)}'
                  : 'Last donation date: ${DateFormat('MMMM d, y').format(_lastDonationDate)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Card(
      elevation: 4,
      child: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2025, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            return Container(
              margin: const EdgeInsets.all(4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _getDayColor(day),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: _getDayColor(day) == Colors.transparent
                      ? null
                      : Colors.white,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Legend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildLegendItem('Last Donation Date', Colors.red),
            SizedBox(height: 8),
            _buildLegendItem('Recovery Period', Colors.orange.withOpacity(0.3)),
            SizedBox(height: 8),
            _buildLegendItem('Next Eligible Date', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}