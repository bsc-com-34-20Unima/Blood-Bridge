import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> events = [];
  String? userId;
  
  // Define the red-ambient gradient colors
  final Color darkRed = const Color(0xFF8B0000);
  final Color lightRed = const Color(0xFFFF5252);

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('user_id');
    });
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Update with your NestJS server URL
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3004/events'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> eventsJson = json.decode(response.body);
        setState(() {
          events = List<Map<String, dynamic>>.from(eventsJson);
        });
      } else {
        debugPrint('Failed to load events: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load events: ${response.statusCode}')),
        );
      }
    } catch (e) {
      debugPrint('Error fetching events: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching events: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _createEvent(Map<String, dynamic> eventData) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3004/events'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(eventData),
      );
      
      if (response.statusCode == 201) {
        _fetchEvents(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create event: ${response.statusCode} - ${response.body}')),
        );
      }
    } catch (e) {
      debugPrint('Error creating event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating event: $e')),
      );
    }
  }

  Future<void> _updateEvent(String id, Map<String, dynamic> eventData) async {
    try {
      final response = await http.patch(
        Uri.parse('http://10.0.2.2:3004/events/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(eventData),
      );
      
      if (response.statusCode == 200) {
        _fetchEvents(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update event: ${response.statusCode}')),
        );
      }
    } catch (e) {
      debugPrint('Error updating event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating event: $e')),
      );
    }
  }

  Future<void> _deleteEvent(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:3004/events/$id'),
      );
      
      if (response.statusCode == 204) {
        _fetchEvents(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete event: ${response.statusCode}')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting event: $e')),
      );
    }
  }

  String _formatDate(String dateString) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final date = DateTime.parse(dateString);
    return dateFormat.format(date);
  }

  void _showEventDetailsDialog(BuildContext context, Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(event['title'] ?? ''),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Date: ${_formatDate(event['eventDate'])}"),
              const SizedBox(height: 4),
              Text("Location: ${event['location'] ?? ''}"),
              const SizedBox(height: 8),
              Text(event['description'] ?? ''),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: darkRed,
                foregroundColor: Colors.white,
              ),
              child: const Text("Close"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddEventDialog(BuildContext context) {
    final titleController = TextEditingController();
    final dateController = TextEditingController();
    final locationController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add New Event"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Event Title"),
                ),
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: "Event Date (YYYY-MM-DD)"),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                      builder: (BuildContext context, Widget? child) {
                        return Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme: ColorScheme.light(
                              primary: darkRed,
                              onPrimary: Colors.white,
                              onSurface: Colors.black,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedDate != null) {
                      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                      dateController.text = formattedDate;
                    }
                  },
                ),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: "Location"),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: darkRed,
                foregroundColor: Colors.white,
              ),
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: darkRed,
                foregroundColor: Colors.white,
              ),
              child: const Text("Add"),
              onPressed: () async {
                // Validate fields
                if (titleController.text.isEmpty ||
                    dateController.text.isEmpty ||
                    locationController.text.isEmpty ||
                    descriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("All fields are required")),
                  );
                  return;
                }
                
                // Format the date for the NestJS API
                final date = DateTime.parse('${dateController.text}T00:00:00.000Z');
                
                final eventData = {
                  'title': titleController.text,
                  'description': descriptionController.text,
                  'eventDate': date.toIso8601String(),
                  'location': locationController.text,
                  'isPublished': true,
                };

                await _createEvent(eventData);
                if (mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditEventDialog(BuildContext context, Map<String, dynamic> event) {
    final String id = event['id'];
    final titleController = TextEditingController(text: event['title']);
    final dateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(DateTime.parse(event['eventDate'])));
    final locationController = TextEditingController(text: event['location']);
    final descriptionController = TextEditingController(text: event['description']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Event"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Event Title"),
                ),
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: "Event Date (YYYY-MM-DD)"),
                  onTap: () async {
                    DateTime initialDate;
                    try {
                      initialDate = DateFormat('yyyy-MM-dd').parse(dateController.text);
                    } catch (e) {
                      initialDate = DateTime.now();
                    }
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                      builder: (BuildContext context, Widget? child) {
                        return Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme: ColorScheme.light(
                              primary: darkRed,
                              onPrimary: Colors.white,
                              onSurface: Colors.black,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedDate != null) {
                      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                      dateController.text = formattedDate;
                    }
                  },
                ),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: "Location"),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: darkRed,
                foregroundColor: Colors.white,
              ),
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: darkRed,
                foregroundColor: Colors.white,
              ),
              child: const Text("Update"),
              onPressed: () async {
                // Validate fields
                if (titleController.text.isEmpty ||
                    dateController.text.isEmpty ||
                    locationController.text.isEmpty ||
                    descriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("All fields are required")),
                  );
                  return;
                }
                
                // Format the date for the NestJS API
                final date = DateTime.parse('${dateController.text}T00:00:00.000Z');
                
                final eventData = {
                  'title': titleController.text,
                  'description': descriptionController.text,
                  'eventDate': date.toIso8601String(),
                  'location': locationController.text,
                };

                await _updateEvent(id, eventData);
                if (mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Event"),
          content: const Text("Are you sure you want to delete this event?"),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: darkRed,
                foregroundColor: Colors.white,
              ),
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: darkRed,
                foregroundColor: Colors.white,
              ),
              child: const Text("Delete"),
              onPressed: () async {
                await _deleteEvent(event['id']);
                if (mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top bar with add button and refresh button on the same line
            Padding(
              padding: const EdgeInsets.only(top: 30.0, bottom: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Add Event Button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Add Event"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: () {
                      _showAddEventDialog(context);
                    },
                  ),
                  
                  // Refresh Button
                  IconButton(
                    icon: Icon(Icons.refresh, color: darkRed, size: 28),
                    onPressed: _fetchEvents,
                    tooltip: 'Refresh events',
                  ),
                ],
              ),
            ),
            
            // Events List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : events.isEmpty
                      ? const Center(child: Text("No events found."))
                      : ListView.builder(
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            final event = events[index];
                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: lightRed.withOpacity(0.2),
                                  child: Icon(Icons.event, color: darkRed),
                                ),
                                title: Text(
                                  event['title'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text("Date: ${_formatDate(event['eventDate'])}"),
                                    Text("Location: ${event['location'] ?? ''}"),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (String value) {
                                    switch (value) {
                                      case 'edit':
                                        _showEditEventDialog(context, event);
                                        break;
                                      case 'delete':
                                        _confirmDelete(context, event);
                                        break;
                                      case 'info':
                                        _showEventDetailsDialog(context, event);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'info',
                                      child: Row(
                                        children: [
                                          Icon(Icons.info, color: Colors.grey),
                                          SizedBox(width: 8),
                                          Text('Info'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}