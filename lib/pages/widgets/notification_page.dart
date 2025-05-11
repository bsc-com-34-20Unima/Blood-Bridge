import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bloodbridge/services/auth_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final AuthService _authService = AuthService();
  List<DonationNotification> _notifications = [];
  bool _isLoading = true;
  
  // API base URL
  final String baseUrl = 'http://192.168.137.86:3004/donation-scheduling';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get token from AuthService
      final String? token = await _authService.getToken();
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to view notifications'))
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Get upcoming donation schedules
      final response = await http.get(
        Uri.parse('$baseUrl/upcoming'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> schedules = json.decode(response.body);
        
        // Convert schedules to notifications
        final List<DonationNotification> notificationsList = schedules.map((schedule) {
          // Create a notification ID based on schedule ID
          final String notificationId = 'schedule_${schedule['id']}';
          
          return DonationNotification(
            id: notificationId,
            title: '${schedule['critical'] ? 'CRITICAL: ' : ''}Blood Donation Need - ${schedule['bloodType']}',
            message: 'Your blood type is needed for donation. Please check if you can help.',
            date: DateTime.parse(schedule['scheduledDate']),
            timeSlot: '${schedule['startTime']} - ${schedule['endTime']}',
            location: schedule['location'],
            isCritical: schedule['critical'] ?? false,
            scheduleId: schedule['id'],
            isRead: false,
          );
        }).toList();
        
        // Mark notifications as read based on shared preferences
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final List<String> readNotificationIds = prefs.getStringList('read_notifications') ?? [];
        
        for (var notification in notificationsList) {
          if (readNotificationIds.contains(notification.id)) {
            notification.isRead = true;
          }
        }
        
        setState(() {
          _notifications = notificationsList;
          _isLoading = false;
        });
        
      } else {
        print('Failed to load notifications: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(DonationNotification notification) async {
    // If already read, no need to do anything
    if (notification.isRead) return;
    
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> readNotificationIds = prefs.getStringList('read_notifications') ?? [];
    
    if (!readNotificationIds.contains(notification.id)) {
      readNotificationIds.add(notification.id);
      await prefs.setStringList('read_notifications', readNotificationIds);
    }
    
    setState(() {
      notification.isRead = true;
    });
  }

  int get unreadNotificationsCount {
    return _notifications.where((notification) => !notification.isRead).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications available'))
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: Colors.red,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return NotificationCard(
                        notification: notification,
                        onTap: () async {
                          await _markAsRead(notification);
                          // Show notification details
                          _showNotificationDetails(notification);
                        },
                      );
                    },
                  ),
                ),
    );
  }

  void _showNotificationDetails(DonationNotification notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.75,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              controller: scrollController,
              children: [
                // Notification title
                Text(
                  notification.title,
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: notification.isCritical ? Colors.red : Colors.black,
                  ),
                ),
                
                const SizedBox(height: 16.0),
                
                // Date
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16.0, color: Colors.grey),
                    const SizedBox(width: 8.0),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(notification.date),
                      style: const TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8.0),
                
                // Time
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16.0, color: Colors.grey),
                    const SizedBox(width: 8.0),
                    Text(
                      notification.timeSlot,
                      style: const TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8.0),
                
                // Location
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16.0, color: Colors.grey),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        notification.location,
                        style: const TextStyle(fontSize: 16.0),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24.0),
                
                // Message
                const Text(
                  'Message:',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  notification.message,
                  style: const TextStyle(fontSize: 16.0),
                ),
                
                const SizedBox(height: 32.0),
                
                // Schedule appointment button
                ElevatedButton(
                  onPressed: () {
                    // Navigate to donation scheduling or details page
                    Navigator.pop(context);
                    // You would implement navigation to the scheduling page here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Navigating to appointment scheduling...'))
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  child: const Text(
                    'Schedule Appointment',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final DonationNotification notification;
  final VoidCallback onTap;
  
  const NotificationCard({
    Key? key,
    required this.notification,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 1.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon or unread indicator
              Container(
                width: 12.0,
                height: 12.0,
                margin: const EdgeInsets.only(top: 4.0, right: 12.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: notification.isRead ? Colors.transparent : Colors.red,
                ),
              ),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                        color: notification.isCritical ? Colors.red : null,
                      ),
                    ),
                    
                    const SizedBox(height: 4.0),
                    
                    // Date & Time
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 12.0, color: Colors.grey),
                        const SizedBox(width: 4.0),
                        Text(
                          DateFormat('MMM d').format(notification.date),
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        const Icon(Icons.access_time, size: 12.0, color: Colors.grey),
                        const SizedBox(width: 4.0),
                        Text(
                          notification.timeSlot,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4.0),
                    
                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12.0, color: Colors.grey),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: Text(
                            notification.location,
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action icon
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DonationNotification {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final String timeSlot;
  final String location;
  final bool isCritical;
  final String scheduleId;
  bool isRead;
  
  DonationNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.timeSlot,
    required this.location,
    required this.isCritical,
    required this.scheduleId,
    this.isRead = false,
  });
}