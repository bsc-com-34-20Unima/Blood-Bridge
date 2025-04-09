import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileSummary extends StatefulWidget {
  const ProfileSummary({super.key});

  @override
  State<ProfileSummary> createState() => _ProfileSummaryState();
}

class _ProfileSummaryState extends State<ProfileSummary> {
  bool isLoading = true;
  Map<String, dynamic> donorData = {};
  Map<String, dynamic> bloodTypeData = {};
  String? userId;
  DateTime? nextEligibilityDate;

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
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (userId == null) return;
    
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch donor data
      final donorResponse = await http.get(
        Uri.parse('http://192.168.137.1:3004/donors/$userId'),
      );
      
      if (donorResponse.statusCode == 200) {
        final donorJson = json.decode(donorResponse.body);
        setState(() {
          donorData = donorJson;
        });
        
        // Fetch blood type data
        if (donorData.containsKey('bloodType')) {
          final bloodTypeResponse = await http.get(
            Uri.parse('http://http://192.168.137.1:3004/blood-types/${donorData['bloodType']}'),
          );
          
          if (bloodTypeResponse.statusCode == 200) {
            setState(() {
              bloodTypeData = json.decode(bloodTypeResponse.body);
            });
          }
        }
        
        // Calculate next eligibility date
        _calculateNextEligibility();
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _calculateNextEligibility() {
    if (donorData.containsKey('lastDonation') && donorData['lastDonation'] != null) {
      final lastDonation = DateTime.parse(donorData['lastDonation']);
      // Assuming 90 days between donations
      nextEligibilityDate = lastDonation.add(const Duration(days: 90));
    }
  }

  Future<void> _updateLastDonation() async {
    final now = DateTime.now();
    try {
      final response = await http.patch(
        Uri.parse('http://192.168.137.1:3004/donors/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'lastDonation': now.toIso8601String(),
        }),
      );
      
      if (response.statusCode == 200) {
        setState(() {
          donorData['lastDonation'] = now.toIso8601String();
        });
        _calculateNextEligibility();
      }
    } catch (e) {
      debugPrint('Error updating last donation: $e');
    }
  }

  int get daysUntilNextEligible {
    if (nextEligibilityDate == null) return 0;
    
    final today = DateTime.now();
    final difference = nextEligibilityDate!.difference(today).inDays;
    return difference > 0 ? difference : 0;
  }

  String _getInitials(String name) {
    List<String> names = name.split(" ");
    String initials = names.map((n) => n.isNotEmpty ? n[0] : "").join();
    return initials.toUpperCase();
  }

  String _formatDate(String dateString) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final date = DateTime.parse(dateString);
    return dateFormat.format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    String initials = _getInitials(donorData['name'] ?? 'User');
    String bloodType = donorData['bloodType'] ?? 'Unknown';
    int donations = donorData['donations'] ?? 0;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profile Avatar + Welcome Message
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[400],
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Welcome! ${donorData['name'] ?? 'User'}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Profile Message (Hardcoded as requested)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Donate Blood, Save Lives",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "20 minutes is all that is required to save lives",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Blood Type Card & Description
              _buildInfoCard("Blood Type", bloodType, const Color.fromARGB(255, 223, 61, 74)),
              const SizedBox(height: 16),
              _buildDescriptionCard(bloodTypeData['description'] ?? 'No description available'),
              const SizedBox(height: 20),

              // Total Donations Card
              _buildInfoCard("Total Donations", donations.toString(), const Color.fromARGB(255, 223, 61, 74)),
              const SizedBox(height: 20),

              // Next Eligibility Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Next Donation Eligibility",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (nextEligibilityDate != null)
                      Text(
                        "You are next eligible to donate in $daysUntilNextEligible days",
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      )
                    else
                      ElevatedButton(
                        onPressed: _updateLastDonation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 223, 61, 74),
                        ),
                        child: const Text(
                          "Update Last Donation Date",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    if (donorData['lastDonation'] != null) 
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Last donated: ${_formatDate(donorData['lastDonation'])}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        description,
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }
}