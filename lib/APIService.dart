import 'dart:convert';
import 'package:http/http.dart' as http;

class Event {
  final String? id;
  final String title;
  final String description;
  final DateTime eventDate;
  final String location;
  final bool isPublished;

  Event({
    this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.location,
    this.isPublished = false,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      eventDate: DateTime.parse(json['eventDate']),
      location: json['location'] ?? '',
      isPublished: json['isPublished'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'eventDate': eventDate.toIso8601String(),
      'location': location,
      'isPublished': isPublished,
    };
  }
}

class EventsApiService {
  // Update with your NestJS server URL
  final String baseUrl = 'http://localhost:3004';  
  
  // Headers for all requests
  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Get all events
  Future<List<Event>> getEvents() async {
    final response = await http.get(
      Uri.parse('$baseUrl/events'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Event.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load events: ${response.statusCode}');
    }
  }

  // Get a single event by id
  Future<Event> getEvent(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/events/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Event.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load event: ${response.statusCode}');
    }
  }

  // Create a new event
  Future<Event> createEvent(Event event) async {
    final response = await http.post(
      Uri.parse('$baseUrl/events'),
      headers: headers,
      body: json.encode(event.toJson()),
    );

    if (response.statusCode == 201) {
      return Event.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create event: ${response.body}');
    }
  }

  // Update an existing event
  Future<Event> updateEvent(String id, Event event) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/events/$id'),
      headers: headers,
      body: json.encode(event.toJson()),
    );

    if (response.statusCode == 200) {
      return Event.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update event: ${response.statusCode}');
    }
  }

  // Delete an event
  Future<void> deleteEvent(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/events/$id'),
      headers: headers,
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete event: ${response.statusCode}');
    }
  }
}