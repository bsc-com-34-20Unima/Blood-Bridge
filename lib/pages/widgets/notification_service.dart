import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bloodbridge/services/auth_service.dart';

class NotificationService {
  // API base URL
  final String baseUrl = 'http://localhost:3005/donation-scheduling';
  
  // Auth service for getting user token
  final AuthService _authService = AuthService();
  
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();
  
  // Fetch upcoming donation schedules as notifications
  Future<List<DonationNotification>> getNotifications() async {
    try {
      // Get token from AuthService
      final String? token = await _authService.getToken();
      
      if (token == null) {
        return [];
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
        await _markReadNotifications(notificationsList);
        
        return notificationsList;
      } else {
        print('Failed to load notifications: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error loading notifications: $e');
      return [];
    }
  }
  
  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> readNotificationIds = prefs.getStringList('read_notifications') ?? [];
    
    if (!readNotificationIds.contains(notificationId)) {
      readNotificationIds.add(notificationId);
      await prefs.setStringList('read_notifications', readNotificationIds);
    }
  }
  
  // Mark notifications as read based on shared preferences
  Future<void> _markReadNotifications(List<DonationNotification> notifications) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> readNotificationIds = prefs.getStringList('read_notifications') ?? [];
    
    for (var notification in notifications) {
      if (readNotificationIds.contains(notification.id)) {
        notification.isRead = true;
      }
    }
  }
  
  // Get unread notifications count
  Future<int> getUnreadCount() async {
    final List<DonationNotification> notifications = await getNotifications();
    return notifications.where((notification) => !notification.isRead).length;
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