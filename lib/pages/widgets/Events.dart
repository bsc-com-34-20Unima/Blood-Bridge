import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Events extends StatefulWidget {
  const Events({super.key});

  @override
  State<Events> createState() => _EventsState();
}

class _EventsState extends State<Events> {
  final TextEditingController _searchController = TextEditingController();
  List<Event> _events = [];
  bool _isLoading = true;
  String _activeFilter = 'Upcoming';
  List<String> _filters = ['Upcoming', 'This Week', 'Weekend'];

  // Example donorId for testing
  final String donorId = '12345'; // Replace with actual donor ID from your authentication logic

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
  setState(() {
    _isLoading = true;
  });

  try {
    // Default endpoint for upcoming events
    String endpoint = 'events';
    
    // Apply filter if selected
    if (_activeFilter == 'This Week') {
      endpoint = 'events/this-week';
    } else if (_activeFilter == 'Weekend') {
      endpoint = 'events/weekend';
    }
    
    // Add search query if any
    if (_searchController.text.isNotEmpty) {
      endpoint += endpoint.contains('?') 
          ? '&search=${_searchController.text}' 
          : '?search=${_searchController.text}';
    }
    
    final response = await http.get(
      Uri.parse('http://192.168.137.86:3004/$endpoint'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      
      // Additional client-side filter to ensure only future events are shown
      // This is a fallback in case the backend filter isn't working
      final now = DateTime.now();
      now.subtract(const Duration(hours: 1)); // Include events starting in the last hour
      
      setState(() {
        _events = data
            .map((event) => Event.fromJson(event))
            .where((event) => event.eventDate.isAfter(now))
            .toList();
        _isLoading = false;
      });
    } else {
      // If the server returns an error
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load events')),
      );
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
    
    // For demo purposes, load sample data but filter past events
    _loadSampleData();
  }
}

// 4. Update the sample data method to filter out past events:
void _loadSampleData() {
  final List<Event> allEvents = [
    Event(
      id: '1',
      title: 'Community Blood Drive',
      location: 'Central Hospital',
      locationAddress: '123 Main Street',
      eventDate: DateTime.now().add(const Duration(days: 2)),
      startTime: '9:00 AM',
      endTime: '4:00 PM',
      description: 'Join us for our community blood drive to help those in need.',
      availableSpots: 24,
      distance: '0.8 miles away',
    ),
    Event(
      id: '2',
      title: 'University Donation Campaign',
      location: 'State University Campus Center',
      locationAddress: '456 University Blvd',
      eventDate: DateTime.now().add(const Duration(days: 5)),
      startTime: '10:00 AM',
      endTime: '6:00 PM',
      description: 'Special blood donation drive targeting university students and staff.',
      availableSpots: 42,
      distance: '1.3 miles away',
    ),
    Event(
      id: '3',
      title: 'Downtown Blood Bank Drive',
      location: 'City Blood Bank',
      locationAddress: '789 Downtown Avenue',
      eventDate: DateTime.now().add(const Duration(days: 8)),
      startTime: '8:00 AM',
      endTime: '2:00 PM',
      description: 'Regularly scheduled donation at the city blood bank.',
      availableSpots: 16,
      distance: '2.7 miles away',
    ),
    Event(
      id: '4',
      title: 'Weekend Community Drive',
      location: 'Westside Community Center',
      locationAddress: '321 West Road',
      eventDate: DateTime.now().add(const Duration(days: 9)),
      startTime: '10:00 AM',
      endTime: '5:00 PM',
      description: 'Weekend community blood drive with family activities.',
      availableSpots: 30,
      distance: '3.2 miles away',
    ),
  ];
  
  // Filter to ensure only future events are shown
  final now = DateTime.now();
  _events = allEvents.where((event) => event.eventDate.isAfter(now)).toList();
  
  setState(() {});
}

  void _applyFilter(String filter) {
    setState(() {
      _activeFilter = filter;
    });
    _fetchEvents();
  }

  void _registerEvent(String eventId, String donorId) async {
    try {
      // Fixed endpoint for registration
      final response = await http.post(
        Uri.parse('http://localhost:3005/events/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'eventId': eventId,
          'donorId': donorId,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registered successfully')),
        );
        // Refresh the events list to show updated availability
        _fetchEvents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _viewDetails(String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Event Details'),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
            color: Colors.red.shade600,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Donation Events',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Find and register for upcoming events',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search events...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _fetchEvents();
                        },
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (_) => _fetchEvents(),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Filter Pills
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _filters.map((filter) => _buildFilterPill(filter)).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Events List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _events.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No events found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          return EventCard(
                            event: _events[index],
                            onRegister: _registerEvent,
                            onViewDetails: _viewDetails,
                            donorId: donorId,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String label) {
    final bool isSelected = _activeFilter == label;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        backgroundColor: isSelected ? Colors.red.shade700 : Colors.grey.shade200,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        onSelected: (_) => _applyFilter(label),
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final Event event;
  final void Function(String eventId, String donorId) onRegister;
  final void Function(String description) onViewDetails;
  final String donorId;

  const EventCard({
    super.key,
    required this.event,
    required this.onRegister,
    required this.onViewDetails,
    required this.donorId,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MMMM d, yyyy');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Header with date badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date badge
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade500,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('dd').format(event.eventDate),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        DateFormat('MMM').format(event.eventDate),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${event.startTime} - ${event.endTime}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Event Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Location
                Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: Colors.red.shade500),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        event.location,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Available Spots
                Row(
                  children: [
                    Icon(Icons.people, size: 18, color: Colors.red.shade500),
                    const SizedBox(width: 12),
                    Text(
                      '${event.availableSpots} spots available',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: event.availableSpots > 0
                            ? () => onRegister(event.id, donorId)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: const Text('Register'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => onViewDetails(event.description),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade600,
                      ),
                      child: const Text('Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Event {
  final String id;
  final String title;
  final String location;
  final String locationAddress;
  final DateTime eventDate;
  final String startTime;
  final String endTime;
  final String description;
  final int availableSpots;
  final String distance;

  Event({
    required this.id,
    required this.title,
    required this.location,
    required this.locationAddress,
    required this.eventDate,
    required this.startTime,
    required this.endTime,
    required this.description,
    required this.availableSpots,
    required this.distance,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      location: json['location'],
      locationAddress: json['locationAddress'] ?? '',
      eventDate: DateTime.parse(json['eventDate']),
      startTime: json['startTime'],
      endTime: json['endTime'],
      description: json['description'],
      availableSpots: json['availableSpots'] ?? 0,
      distance: json['distance'] != null ? '${json['distance']} ${json['distanceUnit'] ?? 'miles away'}' : '',
    );
  }
}