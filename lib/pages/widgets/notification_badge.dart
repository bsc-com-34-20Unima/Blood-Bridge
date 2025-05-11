import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bloodbridge/services/auth_service.dart';
import 'notification_page.dart';

class NotificationBadge extends StatefulWidget {
  const NotificationBadge({Key? key}) : super(key: key);

  @override
  _NotificationBadgeState createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  int _unreadCount = 0;
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  
  // API base URL
  final String baseUrl = 'http://192.168.137.86:3004/donation-scheduling';

  @override
  void initState() {
    super.initState();
    _checkForUnreadNotifications();
  }

  Future<void> _checkForUnreadNotifications() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get token from AuthService
      final String? token = await _authService.getToken();
      
      if (token == null) {
        setState(() {
          _unreadCount = 0;
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
        
        // Get list of read notification IDs from SharedPreferences
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final List<String> readNotificationIds = prefs.getStringList('read_notifications') ?? [];
        
        // Count unread notifications
        int unreadCount = 0;
        for (var schedule in schedules) {
          final String notificationId = 'schedule_${schedule['id']}';
          if (!readNotificationIds.contains(notificationId)) {
            unreadCount++;
          }
        }
        
        setState(() {
          _unreadCount = unreadCount;
          _isLoading = false;
        });
      } else {
        print('Failed to check unread notifications: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking unread notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const NotificationPage())
            ).then((_) {
              // Refresh badge counter when returning from notification page
              _checkForUnreadNotifications();
            });
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}