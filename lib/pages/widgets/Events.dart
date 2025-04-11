// ignore: file_names
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
  String _activeFilter = 'Nearby';
  List<String> _filters = ['Nearby', 'This Week', 'Weekend'];

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
      // Default endpoint
      String endpoint = 'events';
      
      // Apply filter if selected
      if (_activeFilter == 'Nearby') {
        endpoint = 'events/nearby?lat=35.00&lng=-84.00&radius=10';
      } else if (_activeFilter == 'This Week') {
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
        Uri.parse('http://10.0.2.2:3004/$endpoint'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _events = data.map((event) => Event.fromJson(event)).toList();
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
      
      // For demo purposes, load sample data
      _loadSampleData();
    }
  }

  void _loadSampleData() {
    _events = [
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
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3004/events/'), // Correct endpoint for registration
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'eventId': eventId,
          'donorId': donorId, // Include donorId in the request body
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registered successfully')),
        );
        // Optionally, you can refresh the events list or update the local state
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to register')),
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
                  'Blood Donation Events',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Find and register for upcoming donation drives',
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
                
                // Filter Chips
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      FilterChip(
                        label: const Icon(Icons.filter_list, size: 16, color: Colors.white),
                        backgroundColor: Colors.red.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onSelected: (_) {},
                      ),
                      const SizedBox(width: 8),
                      ..._filters.map((filter) => _buildFilterChip(filter)).toList(),
                    ],
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
                    ? const Center(child: Text('No events found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          return EventCard(
                            event: _events[index],
                            onRegister: _registerEvent,
                            onViewDetails: _viewDetails,
                            donorId: donorId, // Pass donorId here
                          );
                        },
                      ),
          ),
          
          // Bottom Navigation
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
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

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return InkWell(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? Colors.red.shade600 : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.red.shade600 : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final Event event;
  final void Function(String eventId, String donorId) onRegister; // Updated to include donorId
  final void Function(String description) onViewDetails;
  final String donorId; // Accept donorId

  const EventCard({
    super.key,
    required this.event,
    required this.onRegister,
    required this.onViewDetails,
    required this.donorId, // Accept donorId
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
          // Event Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                left: BorderSide(color: Colors.red.shade500, width: 4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    event.distance,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
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
                
                // Date
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: Colors.red.shade500),
                    const SizedBox(width: 12),
                    Text(
                      dateFormatter.format(event.eventDate),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Time
                Row(
                  children: [
                    Icon(Icons.access_time, size: 18, color: Colors.red.shade500),
                    const SizedBox(width: 12),
                    Text(
                      '${event.startTime} - ${event.endTime}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
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
                    ElevatedButton(
                      onPressed: () => onRegister(event.id, donorId), // Pass donorId here
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Register'),
                    ),
                    TextButton(
                      onPressed: () => onViewDetails(event.description),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade600,
                      ),
                      child: Row(
                        children: [
                          const Text('View Details'),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 16, color: Colors.red.shade600),
                        ],
                      ),
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
      distance: json['distance'] != null ? '${json['distance']} ${json['distanceUnit'] ?? 'miles away'}' : 'Unknown distance',
    );
  }
}
