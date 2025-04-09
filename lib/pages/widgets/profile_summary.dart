import 'package:bloodbridge/pages/widgets/BloodGroup.dart';
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

class _ProfileSummaryState extends State<ProfileSummary> with SingleTickerProviderStateMixin {
  bool isLoading = true;
  Map<String, dynamic> donorData = {};
  Map<String, dynamic> bloodTypeData = {};
  String? userId;
  DateTime? nextEligibilityDate;
  late TabController _tabController;
  
  // Define the red-ambient gradient colors
  final Color darkRed = const Color(0xFF8B0000);
  final Color lightRed = const Color(0xFFFF5252);
  final Color orange = const Color(0xFFFF9800);
  final Color green = const Color(0xFF4CAF50);


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserId();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        Uri.parse('http://10.0.2.2:3004/donors/$userId'),
      );
      
      if (donorResponse.statusCode == 200) {
        final donorJson = json.decode(donorResponse.body);
        setState(() {
          donorData = donorJson;
        });
        
        // Fetch blood type data using blood group directly
        if (donorData.containsKey('bloodGroup') && donorData['bloodGroup'] != null) {
          final bloodGroupResponse = await http.get(
            Uri.parse('http://10.0.2.2:3004/blood-groups/by-group/${donorData['bloodGroup']}'),
          );
          
          if (bloodGroupResponse.statusCode == 200) {
            setState(() {
              bloodTypeData = json.decode(bloodGroupResponse.body);
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

  Future<void> _updateLastDonation(DateTime selectedDate) async {
    try {
      final response = await http.patch(
        Uri.parse('http://10.0.2.2:3004/donors/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'lastDonation': selectedDate.toIso8601String(),
        }),
      );
      
      if (response.statusCode == 200) {
        setState(() {
          donorData['lastDonation'] = selectedDate.toIso8601String();
        });
        _calculateNextEligibility();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Last donation date updated successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error updating last donation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update donation date')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: donorData['lastDonation'] != null 
          ? DateTime.parse(donorData['lastDonation']) 
          : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
    
    if (picked != null) {
      _updateLastDonation(picked);
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

  EligibilityStatus _getEligibilityStatus() {
    if (nextEligibilityDate == null) {
      return EligibilityStatus.unknown;
    }
    
    final days = daysUntilNextEligible;
    if (days == 0) {
      return EligibilityStatus.eligible;
    } else if (days <= 15) {
      return EligibilityStatus.almostEligible;
    } else {
      return EligibilityStatus.notEligible;
    }
  }

  String _getEligibilityText() {
    switch (_getEligibilityStatus()) {
      case EligibilityStatus.eligible:
        return "Eligible";
      case EligibilityStatus.almostEligible:
        return "Almost There";
      case EligibilityStatus.notEligible:
        return "Not Eligible Yet";
      case EligibilityStatus.unknown:
        return "Unknown Status";
    }
  }

  Color _getEligibilityColor() {
    switch (_getEligibilityStatus()) {
      case EligibilityStatus.eligible:
        return green;
      case EligibilityStatus.almostEligible:
        return orange;
      case EligibilityStatus.notEligible:
        return darkRed;
      case EligibilityStatus.unknown:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    String initials = _getInitials(donorData['name'] ?? 'User');
    String bloodGroup = donorData['bloodGroup'] ?? 'Unknown';

    return Scaffold(
      body: Column(
        children: [
          // App Bar with World Profile and Eligibility
          Container(
            padding: const EdgeInsets.only(top: 40.0, left: 20.0, right: 20.0, bottom: 10.0),
            color: darkRed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Your Profile",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: _getEligibilityColor(),
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Text(
                    _getEligibilityText(),
                    style: const TextStyle(color: Colors.white, fontSize: 14.0),
                  ),
                ),
              ],
            ),
          ),
          
          // Profile section
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  // Profile avatar
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // User name
                  Text(
                    donorData['name'] ?? 'User',
                    style: const TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  // Stats summary
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            const Text(
                              "Total Donations",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "${donorData['donations'] ?? 0}",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Tab Bar with red-ambient gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [darkRed, lightRed],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: const [
                        Tab(text: "Message"),
                        Tab(text: "Blood Type"),
                        Tab(text: "Eligibility"),
                      ],
                    ),
                  ),
                  
                  // Tab Content - Now with flexible height
                  SizedBox(
                    height: 350,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Message Tab
                        _buildMessageTab(),
                        
                        // Blood Type Tab
                        _buildBloodTypeTab(bloodGroup),
                        
                        // Eligibility Tab - Now fully scrollable
                        SingleChildScrollView(
                          child: _buildEligibilityTab(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
        ],
      ),
    );
  }

  Widget _buildNavItem(String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive ? lightRed.withOpacity(0.2) : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              label[0],
              style: TextStyle(
                color: isActive ? darkRed : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? darkRed : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageTab() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Your Donations Save Lives",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: darkRed,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Thank you for being a regular donor!",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Your blood donations have helped save up to 36 lives so far. One donation can save up to 3 lives.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "There is currently a shortage of your blood type in your area. Consider donating this month.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              Center(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: const Text("Schedule Donation"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBloodTypeTab(String bloodGroup) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Blood Type Card
          Card(
            color: darkRed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Blood Type",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bloodGroup,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: Center(
                      child: Text(
                        bloodGroup,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Blood Type Description
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bloodTypeData['description'] ?? 'No description available',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Can donate to: ${bloodTypeData['canDonateTo'] ?? 'Unknown'}",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Can receive from: ${bloodTypeData['canReceiveFrom'] ?? 'Unknown'}",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEligibilityTab() {
    final eligibilityStatus = _getEligibilityStatus();
    Color statusColor;
    String statusText;
    
    switch (eligibilityStatus) {
      case EligibilityStatus.eligible:
        statusColor = green;
        statusText = "You are eligible to donate now!";
        break;
      case EligibilityStatus.almostEligible:
        statusColor = orange;
        statusText = "Almost there! Just a few more days.";
        break;
      case EligibilityStatus.notEligible:
        statusColor = darkRed;
        statusText = "Not eligible yet. Please wait until eligibility date.";
        break;
      case EligibilityStatus.unknown:
      default:
        statusColor = Colors.grey;
        statusText = "No donation history found.";
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Next Donation Eligibility",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkRed,
                ),
              ),
              const SizedBox(height: 20),
              if (nextEligibilityDate != null) ...[
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: statusColor,
                      child: Text(
                        daysUntilNextEligible.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (daysUntilNextEligible > 0) ...[
                            const SizedBox(height: 6),
                            Text(
                              "You can donate on ${_formatDate(nextEligibilityDate!.toIso8601String())}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (donorData['lastDonation'] != null) ...[
                  const Text(
                    "Last Donation:",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(donorData['lastDonation']),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ] else ...[
                const Text(
                  "We don't have your last donation date on record.",
                  style: TextStyle(fontSize: 16),
                ),
              ],
              
              // Always show update button
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _selectDate(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.calendar_month),
                  label: const Text("Update Donation Date"),
                ),
              ),
              // Add extra space at the bottom to ensure everything is visible when scrolling
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// Enum to track eligibility status
enum EligibilityStatus {
  eligible,
  almostEligible,
  notEligible,
  unknown
}