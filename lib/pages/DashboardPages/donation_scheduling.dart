import 'package:bloodbridge/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';

class DonationSchedulePage extends StatefulWidget {
  const DonationSchedulePage({Key? key}) : super(key: key);

  @override
  _DonationSchedulePageState createState() => _DonationSchedulePageState();
}

class _DonationSchedulePageState extends State<DonationSchedulePage> {
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late Map<DateTime, List<dynamic>> _events;
  late List<dynamic> _selectedEvents;
  
  // API base URL
  final String baseUrl = 'https://blood-bridge-2f7x.onrender.com/donation-scheduling';
  
  // Auth service instance
  final AuthService _authService = AuthService();

  
  
  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _events = {};
    _selectedEvents = [];
    _loadEvents();
  }
  
 // In the _DonationSchedulePageState class, modify the _loadEvents method

 // Add this method to your _DonationSchedulePageState class
void _showManageScheduleDialog(BuildContext context, dynamic schedule) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
    ),
    builder: (context) => ManageScheduleDialog(
      schedule: schedule,
      onScheduleUpdated: () {
        // Reload schedules after update
        _loadEvents();
        _loadSchedulesForDate(_selectedDay);
      },
      onScheduleDeleted: () {
        // Reload schedules after deletion
        _loadEvents();
        _loadSchedulesForDate(_selectedDay);
      },
    ),
  );
}

Future<void> _loadEvents() async {
  final int year = _focusedDay.year;
  final int month = _focusedDay.month;
  
  try {
    // Get token from AuthService
    final String? token = await _authService.getToken();
    
    if (token == null) {
      // Handle not authenticated state
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to view schedules'))
      );
      return;
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/calendar/$year/$month'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> daysWithSchedules = json.decode(response.body);
      final Map<DateTime, List<dynamic>> newEvents = {};
      
      for (final day in daysWithSchedules) {
        final eventDate = DateTime(year, month, day);
        newEvents[eventDate] = [true]; // Mark date as having an event
      }
      
      setState(() {
        _events = newEvents;
      });
      
      // Load events for selected day
      _loadSchedulesForDate(_selectedDay);
    } else {
      print('Failed to load calendar events: ${response.statusCode}');
      // Show an error message or handle gracefully
      setState(() {
        _events = {};
      });
    }
  } catch (e) {
    print('Error loading calendar events: $e');
    // Show an error message
    setState(() {
      _events = {};
    });
  }
}



  
  Future<void> _loadSchedulesForDate(DateTime date) async {
    final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    
    try {
      // Get token from AuthService
      final String? token = await _authService.getToken();
      
      if (token == null) {
        return;
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/date/$formattedDate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        setState(() {
          _selectedEvents = json.decode(response.body);
        });
      } else {
        print('Failed to load schedules: ${response.statusCode}');
        setState(() {
          _selectedEvents = [];
        });
      }
    } catch (e) {
      print('Error loading schedules: $e');
      setState(() {
        _selectedEvents = [];
      });
    }
  }
  
  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }
  
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      
      _loadSchedulesForDate(selectedDay);
    }
  }
  
  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });
    
    // Load events for the new month
    _loadEvents();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Calendar
          Card(
            margin: const EdgeInsets.all(8.0),
            elevation: 2.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                eventLoader: _getEventsForDay,
                startingDayOfWeek: StartingDayOfWeek.sunday,
                calendarStyle: CalendarStyle(
                  markerDecoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                ),
                onDaySelected: _onDaySelected,
                onPageChanged: _onPageChanged,
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
              ),
            ),
          ),
          
          // Selected date display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEE, MMM d').format(_selectedDay),
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_selectedEvents.length} ${_selectedEvents.length == 1 ? 'session' : 'sessions'} scheduled',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Scheduled donations header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Scheduled Donations',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'All blood types',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16.0,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Donation schedules list
          Expanded(
            child: _selectedEvents.isEmpty
                ? const Center(
                    child: Text('No donation sessions scheduled for this day'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _selectedEvents.length,
                    itemBuilder: (context, index) {
                      final schedule = _selectedEvents[index];
                      return DonationScheduleCard(schedule: schedule);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
    backgroundColor: Colors.red,
    onPressed: () {
      _showCreateScheduleDialog(context);
    },
    icon: const Icon(Icons.add, color: Colors.white),
    label: const Text(
      'Schedule New Donation Session',
      style: TextStyle(color: Colors.white),
    ),
  ),
  floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,);
  }
  
  void _showCreateScheduleDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => CreateDonationScheduleForm(
        selectedDate: _selectedDay,
        onScheduleCreated: () {
          // Reload schedules after creation
          _loadEvents();
          _loadSchedulesForDate(_selectedDay);
        },
      ),
    );
  }
}

class DonationScheduleCard extends StatelessWidget {
  final dynamic schedule;
  
  const DonationScheduleCard({
    Key? key,
    required this.schedule,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final bool isCritical = schedule['critical'] == true;
    final String bloodType = schedule['bloodType'];
    final int unitsRequired = schedule['unitsRequired'];
    final int donorsAssigned = schedule['donorsAssigned'];
    final String startTime = schedule['startTime']; 
    final String endTime = schedule['endTime']; 
    final String location = schedule['location']; 
    final String sessionId = schedule['id'];
    
    Color indicatorColor = isCritical ? Colors.red : Colors.blue;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 1.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left color indicator
            Container(
              width: 6.0,
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  bottomLeft: Radius.circular(8.0),
                ),
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Blood type and status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              bloodType,
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isCritical)
                              Container(
                                margin: const EdgeInsets.only(left: 8.0),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 4.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: const Text(
                                  'Critical',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4.0),
                    
                    Text(
                      '$unitsRequired units required',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey[700],
                      ),
                    ),
                    
                    const SizedBox(height: 16.0),
                    
                    // Time information - show start and end times separately
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16.0,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          '$startTime to $endTime',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8.0),
                    
                    // Location information
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16.0,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          location,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16.0),
                    
                    // Session ID and manage button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                   

                      ],
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

class CreateDonationScheduleForm extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback onScheduleCreated;
  
  const CreateDonationScheduleForm({
    Key? key,
    required this.selectedDate,
    required this.onScheduleCreated,
  }) : super(key: key);
  
  @override
  _CreateDonationScheduleFormState createState() => _CreateDonationScheduleFormState();
}

class _CreateDonationScheduleFormState extends State<CreateDonationScheduleForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Form fields
  String _bloodType = 'All';
  int _unitsRequired = 1;
  DateTime _selectedDate = DateTime.now();
  String _startTime = '9:00 AM';
  String _endTime = '11:00 AM';
  int _donorsNeeded = 1;
  bool _isCritical = false;
  String _notes = '';
  String _location = '';
  
  // Blood type options with "All" option
  final List<String> _bloodTypes = [
    'All', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];
  
  // API base URL
  final String baseUrl = 'https://blood-bridge-2f7x.onrender.com/donation-scheduling';
  
  // Auth service
  final AuthService _authService = AuthService();
  
  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 9, minute: 0),
    );
    
    if (picked != null) {
      setState(() {
        _startTime = _formatTimeOfDay(picked);
      });
    }
  }
  
  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 11, minute: 0),
    );
    
    if (picked != null) {
      setState(() {
        _endTime = _formatTimeOfDay(picked);
      });
    }
  }
  
  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    final period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }




  
// In _CreateDonationScheduleFormState class, modify the _submitForm method
Future<void> _submitForm() async {
  if (_formKey.currentState!.validate()) {
    // Get token from auth service
    final String? token = await _authService.getToken();
    String? hospitalId = await _authService.getUserId(); // Get hospital ID
    
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authenticated. Please login again.'))
      );
      return;
    }
    
    if (hospitalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hospital ID not found. Please check your account settings.'))
      );
      return;
    }
    
    // Format date as ISO string as the backend expects a Date object
    final String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    
    // Create request payload
    final Map<String, dynamic> payload = {
      'bloodType': _bloodType == 'All' ? 'All' : _bloodType,
      'unitsRequired': _unitsRequired,
      'scheduleDate': formattedDate, // Changed from scheduledDate to scheduleDate
      'startTime': _startTime,
      'endTime': _endTime,
      'donorsNeeded': _donorsNeeded,
      'critical': _isCritical,
      'notes': _notes.isEmpty ? '' : _notes,
      'location': _location,
      'hospitalId': hospitalId, // Add hospitalId to payload
    };
    
    try {
      print('Sending payload: ${json.encode(payload)}'); // Debug log
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 201) {
        // Success
        Navigator.pop(context);
        widget.onScheduleCreated();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation schedule created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Error
        print('Error response body: ${response.body}'); // Debug log
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create schedule: ${response.statusCode} - ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Exception: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
  
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              children: [
                // Title
                const Center(
                  child: Text(
                    'Schedule Donation Session',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24.0),
                
                // Date Picker Field
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today,),
                      ),
                      controller: TextEditingController(
                        text: DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a date';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 16.0),
                
                // Location Field
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'Enter donation location',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _location = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a location';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16.0),
                
                // Blood Type
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Blood Type',
                    border: OutlineInputBorder(),
                  ),
                  value: _bloodType,
                  items: _bloodTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _bloodType = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a blood type';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16.0),
                
                // Units Required
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Units Required',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: _unitsRequired.toString(),
                  onChanged: (value) {
                    setState(() {
                      _unitsRequired = int.tryParse(value) ?? 1;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the number of units required';
                    }
                    if (int.tryParse(value) == null || int.parse(value) < 1) {
                      return 'Please enter a valid number (minimum 1)';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16.0),
                
                // Start Time
                GestureDetector(
                  onTap: _selectStartTime,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Start Time',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time, ),
                      ),
                      controller: TextEditingController(text: _startTime),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a start time';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 16.0),
                
                // End Time
                GestureDetector(
                  onTap: _selectEndTime,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'End Time',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time,),
                      ),
                      controller: TextEditingController(text: _endTime),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select an end time';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 16.0),
                
                // Donors Needed
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Donors Needed',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: _donorsNeeded.toString(),
                  onChanged: (value) {
                    setState(() {
                      _donorsNeeded = int.tryParse(value) ?? 1;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the number of donors needed';
                    }
                    if (int.tryParse(value) == null || int.parse(value) < 1) {
                      return 'Please enter a valid number (minimum 1)';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16.0),
                
                // Critical Toggle
                SwitchListTile(
                  title: const Text('Critical Need'),
                  subtitle: const Text('Mark this as a critical blood donation need'),
                  value: _isCritical,
                  activeColor: Colors.red,
                  onChanged: (bool value) {
                    setState(() {
                      _isCritical = value;
                    });
                  },
                ),
                
                const SizedBox(height: 16.0),
                
                // Notes
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Additional Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    setState(() {
                      _notes = value;
                    });
                  },
                ),
                
                const SizedBox(height: 24.0),
                
                // Submit Button
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: const Text(
                    'Create Schedule',
                    style: TextStyle(fontSize: 16.0, color: Colors.white),
                  ),
                ),
                
                const SizedBox(height: 16.0),
                
                // Cancel Button
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// New ManageScheduleDialog class - add this to your file
class ManageScheduleDialog extends StatefulWidget {
  final dynamic schedule;
  final VoidCallback onScheduleUpdated;
  final VoidCallback onScheduleDeleted;
  
  const ManageScheduleDialog({
    Key? key,
    required this.schedule,
    required this.onScheduleUpdated,
    required this.onScheduleDeleted,
  }) : super(key: key);
  
  @override
  _ManageScheduleDialogState createState() => _ManageScheduleDialogState();
}

class _ManageScheduleDialogState extends State<ManageScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Form fields - initialize from existing schedule
  late String _bloodType;
  late int _unitsRequired;
  late DateTime _selectedDate;
  late String _startTime;
  late String _endTime;
  late int _donorsNeeded;
  late bool _isCritical;
  late String _notes;
  late String _location;
  
  // Blood type options
  final List<String> _bloodTypes = [
    'All', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];
  
  // API base URL
  final String baseUrl = 'https://blood-bridge-2f7x.onrender.com/donation-scheduling';
  
  // Auth service
  final AuthService _authService = AuthService();
  
  @override
  void initState() {
    super.initState();
    // Initialize form fields with existing schedule data
    _bloodType = widget.schedule['bloodType'] ?? 'All';
    _unitsRequired = widget.schedule['unitsRequired'] ?? 1;
    _selectedDate = DateTime.parse(widget.schedule['scheduledDate'] ?? DateTime.now().toString());
    _startTime = widget.schedule['startTime'] ?? '9:00 AM';
    _endTime = widget.schedule['endTime'] ?? '11:00 AM';
    _donorsNeeded = widget.schedule['donorsNeeded'] ?? 1;
    _isCritical = widget.schedule['critical'] ?? false;
    _notes = widget.schedule['notes'] ?? '';
    _location = widget.schedule['location'] ?? '';
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _parseTimeString(_startTime),
    );
    
    if (picked != null) {
      setState(() {
        _startTime = _formatTimeOfDay(picked);
      });
    }
  }
  
  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _parseTimeString(_endTime),
    );
    
    if (picked != null) {
      setState(() {
        _endTime = _formatTimeOfDay(picked);
      });
    }
  }
  
  TimeOfDay _parseTimeString(String timeString) {
    // Parse "9:00 AM" format
    final parts = timeString.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final period = parts[1];
    
    if (period == 'PM' && hour != 12) {
      hour += 12;
    } else if (period == 'AM' && hour == 12) {
      hour = 0;
    }
    
    return TimeOfDay(hour: hour, minute: minute);
  }
  
  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    final period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
  
  Future<void> _updateSchedule() async {
    if (_formKey.currentState!.validate()) {
      final String? token = await _authService.getToken();
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not authenticated. Please login again.'))
        );
        return;
      }
      
      final String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      final Map<String, dynamic> payload = {
        'bloodType': _bloodType,
        'unitsRequired': _unitsRequired,
        'scheduledDate': formattedDate,
        'startTime': _startTime,
        'endTime': _endTime,
        'donorsNeeded': _donorsNeeded,
        'critical': _isCritical,
        'notes': _notes,
        'location': _location,
      };
      
      try {
        final response = await http.patch(
          Uri.parse('$baseUrl/${widget.schedule['id']}'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(payload),
        );
        
        if (response.statusCode == 200) {
          Navigator.pop(context);
          widget.onScheduleUpdated();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Schedule updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update schedule: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _deleteSchedule() async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: const Text('Are you sure you want to delete this donation schedule? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    final String? token = await _authService.getToken();
    
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authenticated. Please login again.'))
      );
      return;
    }
    
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/${widget.schedule['id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        Navigator.pop(context);
        widget.onScheduleDeleted();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete schedule: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              children: [
                // Title with delete button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Manage Donation Schedule',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: _deleteSchedule,
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete Schedule',
                    ),
                  ],
                ),
                
                const SizedBox(height: 24.0),
                
                // Session ID display
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    'Session ID: #${widget.schedule['id'].toString().substring(0, 5)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16.0),
                
                // Date Picker Field
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      controller: TextEditingController(
                        text: DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a date';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 16.0),
                
                // Location Field
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'Enter donation location',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _location,
                  onChanged: (value) {
                    setState(() {
                      _location = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a location';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16.0),
                
                // Blood Type
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Blood Type',
                    border: OutlineInputBorder(),
                  ),
                  value: _bloodType,
                  items: _bloodTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _bloodType = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a blood type';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16.0),
                
                // Units Required
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Units Required',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: _unitsRequired.toString(),
                  onChanged: (value) {
                    setState(() {
                      _unitsRequired = int.tryParse(value) ?? 1;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the number of units required';
                    }
                    if (int.tryParse(value) == null || int.parse(value) < 1) {
                      return 'Please enter a valid number (minimum 1)';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16.0),
                
                // Start Time
                GestureDetector(
                  onTap: _selectStartTime,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Start Time',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      controller: TextEditingController(text: _startTime),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a start time';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 16.0),
                
                // End Time
                GestureDetector(
                  onTap: _selectEndTime,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'End Time',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      controller: TextEditingController(text: _endTime),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select an end time';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 16.0),
                
                // Donors Needed
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Donors Needed',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: _donorsNeeded.toString(),
                  onChanged: (value) {
                    setState(() {
                      _donorsNeeded = int.tryParse(value) ?? 1;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the number of donors needed';
                    }
                    if (int.tryParse(value) == null || int.parse(value) < 1) {
                      return 'Please enter a valid number (minimum 1)';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16.0),
                
                // Critical Toggle
                SwitchListTile(
                  title: const Text('Critical Need'),
                  subtitle: const Text('Mark this as a critical blood donation need'),
                  value: _isCritical,
                  activeColor: Colors.red,
                  onChanged: (bool value) {
                    setState(() {
                      _isCritical = value;
                    });
                  },
                ),
                
                const SizedBox(height: 16.0),
                
                // Notes
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Additional Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  initialValue: _notes,
                  onChanged: (value) {
                    setState(() {
                      _notes = value;
                    });
                  },
                ),
                
                const SizedBox(height: 24.0),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _updateSchedule,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: const Text(
                          'Update Schedule',
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16.0),
              ],
            ),
          ),
        );
      },
    );
  }
}