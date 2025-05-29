import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Enum to track eligibility status
enum EligibilityStatus {
  eligible,
  almostEligible,
  notEligible,
  unknown
}

// Adding enum for donor status
enum DonorStatus {
  ACTIVE,
  PENDING,
  RESTRICTED,
  INACTIVE
}

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
  DonorStatus? donorStatus;
  
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
        Uri.parse('https://blood-bridge-2f7x.onrender.com/donors/$userId'),
      );
      
      if (donorResponse.statusCode == 200) {
        final donorJson = json.decode(donorResponse.body);
        setState(() {
          donorData = donorJson;
          // Parse the donor status from the API response
          if (donorData.containsKey('status') && donorData['status'] != null) {
            donorStatus = _parseDonorStatus(donorData['status']);
          }
        });
        
        // Fetch blood type data using blood group directly
        if (donorData.containsKey('bloodGroup') && donorData['bloodGroup'] != null) {
          final bloodGroupResponse = await http.get(
            Uri.parse('https://blood-bridge-2f7x.onrender.com/blood-groups/by-group/${donorData['bloodGroup']}'),
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

  // Parse the donor status string from the API into the enum
  DonorStatus _parseDonorStatus(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return DonorStatus.ACTIVE;
      case 'PENDING':
        return DonorStatus.PENDING;
      case 'RESTRICTED':
        return DonorStatus.RESTRICTED;
      case 'INACTIVE':
        return DonorStatus.INACTIVE;
      default:
        return DonorStatus.INACTIVE;
    }
  }

  // Get color based on the donor status
  Color _getDonorStatusColor(DonorStatus status) {
    switch (status) {
      case DonorStatus.ACTIVE:
        return green;
      case DonorStatus.PENDING:
        return orange;
      case DonorStatus.RESTRICTED:
        return darkRed;
      case DonorStatus.INACTIVE:
        return Colors.grey;
    }
  }

  // Get text for donor status
  String _getDonorStatusText(DonorStatus status) {
    switch (status) {
      case DonorStatus.ACTIVE:
        return "Active";
      case DonorStatus.PENDING:
        return "Pending";
      case DonorStatus.RESTRICTED:
        return "Restricted";
      case DonorStatus.INACTIVE:
        return "Inactive";
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
        Uri.parse('https://blood-bridge-2f7x.onrender.com/donors/$userId'),
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
    // If donor status is inactive, return not eligible
    if (donorStatus == DonorStatus.INACTIVE) {
      return EligibilityStatus.notEligible;
    }
    
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
          // App Bar with only Donor Status (no eligibility)
          Container(
            padding: const EdgeInsets.only(top: 40.0, left: 20.0, right: 20.0, bottom: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end, // Align to the right
              children: [
                // Only Donor Status Indicator
                if (donorStatus != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: _getDonorStatusColor(donorStatus!),
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Text(
                      _getDonorStatusText(donorStatus!),
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
                        // Message Tab with Donor Status
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
    child: SingleChildScrollView(  // Add this SingleChildScrollView wrapper
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
                "Your blood donations have helped save so many lives. One donation can save up to 3 lives.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Blood is usually needded in hospitals due to having less blood units. Consider donating this month and invite others.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              // Show current donor status
              const SizedBox(height: 20),
              if (donorStatus != null) ...[
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      height: 16,
                      width: 16,
                      decoration: BoxDecoration(
                        color: _getDonorStatusColor(donorStatus!),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Account Status: ${_getDonorStatusText(donorStatus!)}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _getDonorStatusColor(donorStatus!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _getDonorStatusDescription(donorStatus!),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
              const SizedBox(height: 20),  // Replace Spacer() with SizedBox
            ],
          ),
        ),
      ),
    ),
  );
}

  // Get description based on donor status
  String _getDonorStatusDescription(DonorStatus status) {
    switch (status) {
      case DonorStatus.ACTIVE:
        return "Your are an active donor. You can schedule donations when eligible.";
      case DonorStatus.PENDING:
        return "Your account is pending verification. Please wait for further info from the recent donation center.";
      case DonorStatus.RESTRICTED:
        return "Your account is restricted, please seek medical attention. Please contact support for more information.";
      case DonorStatus.INACTIVE:
        return "Please seek immediate medical support for more info. Seek your previous donation center for more info.";
    }
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
    bool isInactive = donorStatus == DonorStatus.INACTIVE;
    
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
        statusText = isInactive ? "You are not eligible" : "Not eligible yet. Please wait until eligibility date.";
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
              // Special case for INACTIVE status
              if (isInactive) ...[
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: statusColor,
                        child: const Icon(
                          Icons.block,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        statusText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Your account is currently inactive. Please seek your recent donation center or contact support.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (nextEligibilityDate != null) ...[
                // Normal display for active accounts
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
                  
                  // Update button for active accounts
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
                ],
              ] else ...[
                // No donation history for active accounts
                const Text(
                  "We don't have your last donation date on record.",
                  style: TextStyle(fontSize: 16),
                ),
                
                // Show update button for active accounts with no history
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
                    label: const Text("Add Donation Date"),
                  ),
                ),
              ],
              // Add extra space at the bottom to ensure everything is visible when scrolling
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}