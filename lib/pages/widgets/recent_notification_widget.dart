import 'package:bloodbridge/pages/widgets/notification_page.dart';
import 'package:bloodbridge/pages/widgets/notification_service.dart' as service;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecentNotificationsWidget extends StatefulWidget {
  const RecentNotificationsWidget({Key? key}) : super(key: key);

  @override
  _RecentNotificationsWidgetState createState() => _RecentNotificationsWidgetState();
}

class _RecentNotificationsWidgetState extends State<RecentNotificationsWidget> {
  List<service.DonationNotification> _notifications = [];
  bool _isLoading = true;
  final service.NotificationService _notificationService = service.NotificationService();
  
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
      final notifications = await _notificationService.getNotifications();
      
      setState(() {
        // Take just the most recent 3 notifications
        _notifications = notifications.take(3).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading recent notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Notifications',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationPage()),
                    ).then((_) => _loadNotifications());
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8.0),
            _buildNotificationsList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotificationsList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );
    }
    
    if (_notifications.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Text(
            'No notifications available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    
    return Column(
      children: _notifications.map((notification) {
        return _buildNotificationItem(notification);
      }).toList(),
    );
  }
  
  Widget _buildNotificationItem(service.DonationNotification notification) {
    return InkWell(
      onTap: () async {
        // Mark notification as read
        await _notificationService.markAsRead(notification.id);
        
        // Navigate to notification page
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationPage()),
          ).then((_) => _loadNotifications());
        }
      },
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification indicator
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
            
            // Chevron icon
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}