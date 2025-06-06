import 'package:bloodbridge/pages/DashboardPages/BloodInventory.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bloodbridge/services/auth_service.dart'; // Update import path if needed

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  late Future<List<BloodInventory>> _inventoryFuture;
  late Future<int> _eventsFuture;
  late Future<int> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _inventoryFuture = _apiService.fetchInventory();
    _eventsFuture = _fetchEventCount();
    _requestsFuture = _fetchRequestCount();
  }

  Future<int> _fetchRequestCount() async {
    try {
      final userId = await _authService.getUserId();
      final userRole = await _authService.getUserRole();
      
      // Only fetch requests if user is a hospital
      if (userRole != UserRole.hospital || userId == null) {
        return 0;
      }
      
      final token = await _authService.getToken();
      if (token == null) {
        debugPrint('No auth token found');
        return 0;
      }
      
      // Use authenticated request through AuthService
      final response = await _authService.authenticatedRequest(
        'blood-requests/hospital/$userId',
        method: 'GET',
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> requestsJson = json.decode(response.body);
        // Filter for pending requests only
        final pendingRequests = requestsJson.where((req) => 
            req['status'] == 'PENDING' || req['status'] == 'pending').toList();
        return pendingRequests.length;
      } else {
        debugPrint('Failed to load requests: ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      debugPrint('Error fetching requests: $e');
      return 0;
    }
  }

  Future<int> _fetchEventCount() async {
    try {
      final response = await http.get(
        Uri.parse('https://blood-bridge-2f7x.onrender.com/events'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> eventsJson = json.decode(response.body);
        return eventsJson.length;
      } else {
        debugPrint('Failed to load events: ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      debugPrint('Error fetching events: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BloodInventory>>(
      future: _inventoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final bloodInventories = snapshot.data ?? [];
        int totalUnits = bloodInventories.fold(0, (sum, item) => sum + item.availableUnits);
        String criticalGroups = _getCriticalShortagesString(bloodInventories);

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildDashboardCard(
                    title: "Total Blood Units",
                    value: "$totalUnits units",
                    icon: LucideIcons.droplet,
                    iconColor: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<int>(
                    future: _requestsFuture,
                    builder: (context, requestSnapshot) {
                      if (requestSnapshot.connectionState == ConnectionState.waiting) {
                        return _buildDashboardCard(
                          title: "Pending Requests",
                          value: "Loading...",
                          icon: LucideIcons.fileClock,
                          iconColor: Colors.orange,
                        );
                      } else if (requestSnapshot.hasError) {
                        return _buildDashboardCard(
                          title: "Pending Requests",
                          value: "Error loading",
                          icon: LucideIcons.fileClock,
                          iconColor: Colors.orange,
                        );
                      }
                      
                      final requestCount = requestSnapshot.data ?? 0;
                      return _buildDashboardCard(
                        title: "Pending Requests",
                        value: "$requestCount ${requestCount == 1 ? 'request' : 'requests'}",
                        icon: LucideIcons.fileClock,
                        iconColor: Colors.orange,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDashboardCard(
                    title: "Critical Shortage",
                    value: criticalGroups,
                    icon: LucideIcons.alertTriangle,
                    iconColor: Colors.deepPurple,
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<int>(
                    future: _eventsFuture,
                    builder: (context, eventSnapshot) { 
                      final eventCount = eventSnapshot.data ?? 0;
                      return _buildDashboardCard(
                        title: "Upcoming Events",
                        value: "$eventCount ${eventCount == 1 ? 'event' : 'events'}",
                        icon: LucideIcons.calendarClock,
                        iconColor: Colors.green,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  String _getCriticalShortagesString(List<BloodInventory> inventories) {
    final criticalGroups = inventories
        .where((item) => item.status == "Critical Shortage")
        .map((item) => item.bloodGroup)
        .toList();

    return criticalGroups.isNotEmpty ? criticalGroups.join(', ') : 'None';
  }
}