// Let's complete the implementation for the DonorsPage widget

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Donor model from the first document
class Donor {
  String id;
  String name;
  String bloodGroup;
  String lastDonation;
  String status;
  String contact;
  String donorId;
  String email;

  Donor({
    required this.id,
    required this.name, 
    required this.bloodGroup, 
    required this.lastDonation,
    this.status = 'Active',
    required this.contact,
    required this.donorId,
    required this.email,
  });

  factory Donor.fromJson(Map<String, dynamic> json) {
    return Donor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      bloodGroup: json['bloodGroup'] ?? '',
      lastDonation: json['lastDonation'] != null 
          ? DateTime.parse(json['lastDonation']).toString().substring(0, 10)
          : 'No donation yet',
      status: json['status'] ?? 'Active',
      contact: json['phone'] ?? '',
      donorId: json['id']?.substring(0, 8) ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bloodGroup': bloodGroup,
      'status': status,
      'phone': contact,
      'email': email,
    };
  }
}

// DonorService class from the first document
class DonorService {
  final String baseUrl = 'https://blood-bridge-2f7x.onrender.com/donors'; // Change this to your actual API URL
  
  Future<List<Donor>> getDonors({String? bloodGroup, String? status, String? search}) async {
    try {
      // Build query parameters
      Map<String, String> queryParams = {};
      if (bloodGroup != null && bloodGroup != 'All Blood Types') {
        queryParams['bloodGroup'] = bloodGroup;
      }
      if (status != null && status != 'All Statuses') {
        queryParams['status'] = status;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      // Build URL with query parameters
      Uri uri = Uri.parse(baseUrl);
      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Donor.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load donors: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching donors: $e');
    }
  }
  
  Future<Donor> getDonor(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$id'));
      
      if (response.statusCode == 200) {
        return Donor.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load donor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching donor: $e');
    }
  }
  
  Future<Donor> updateDonorStatus(String id, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$id/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      );
      
      if (response.statusCode == 200) {
        return Donor.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update donor status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating donor status: $e');
    }
  }
  
  Future<Donor> updateDonor(String id, Map<String, dynamic> donorData) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(donorData),
      );
      
      if (response.statusCode == 200) {
        return Donor.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update donor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating donor: $e');
    }
  }
  
  Future<void> deleteDonor(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to delete donor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting donor: $e');
    }
  }

  Future<List<Donor>> findNearbyDonors({
    required double latitude,
    required double longitude,
    double radius = 10,
    String? bloodGroup,
  }) async {
    try {
      // Build query parameters
      Map<String, String> queryParams = {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius': radius.toString(),
      };
      
      if (bloodGroup != null && bloodGroup != 'All Blood Types') {
        queryParams['bloodGroup'] = bloodGroup;
      }
      
      // Build URL with query parameters
      Uri uri = Uri.parse('$baseUrl/nearby').replace(queryParameters: queryParams);
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Donor.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load nearby donors: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching nearby donors: $e');
    }
  }

  Future<Map<String, dynamic>> getBloodGroupInsufficiency(String bloodGroup) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/blood-group-insufficiency').replace(
          queryParameters: {'bloodGroup': bloodGroup},
        ),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to check blood group insufficiency: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error checking blood group insufficiency: $e');
    }
  }
}

// Complete DonorsPage widget
class DonorsPage extends StatefulWidget {
  const DonorsPage({Key? key}) : super(key: key);

  @override
  _DonorsPageState createState() => _DonorsPageState();
}

class _DonorsPageState extends State<DonorsPage> {
  final DonorService _donorService = DonorService();
  List<Donor> donors = [];
  List<Donor> filteredDonors = [];
  bool isLoading = true;
  String selectedBloodType = 'Blood Types';
  String selectedStatus = 'Statuses';
  String selectedTimeframe = 'All Time';
  String searchQuery = '';

  final List<String> bloodTypes = ['Blood Types', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> statusOptions = ['Statuses', 'Active', 'Pending', 'Ineligible'];

  @override
  void initState() {
    super.initState();
    _fetchDonors();
  }

  Future<void> _fetchDonors() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final fetchedDonors = await _donorService.getDonors(
        bloodGroup: selectedBloodType != 'Blood Types' ? selectedBloodType : null,
        status: selectedStatus != 'Statuses' ? selectedStatus : null,
        search: searchQuery.isNotEmpty ? searchQuery : null,
      );
      
      setState(() {
        donors = fetchedDonors;
        filteredDonors = fetchedDonors;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load donors: $e')),
      );
    }
  }

  void _filterDonors(String query) {
    setState(() {
      searchQuery = query;
    });
    
    // For immediate filtering without API call
    if (query.isEmpty) {
      _applyFilters();
    } else {
      setState(() {
        filteredDonors = donors
            .where((donor) => 
                donor.name.toLowerCase().contains(query.toLowerCase()) ||
                donor.donorId.toLowerCase().contains(query.toLowerCase()) ||
                donor.bloodGroup.toLowerCase().contains(query.toLowerCase())
            )
            .toList();
      });
    }
    
    // Optional: Make API call for more accurate search if needed
    _fetchDonors();
  }

  void _applyFilters() {
    _fetchDonors();
  }

  void _showStatusUpdateDialog(int index) async {
    String currentStatus = filteredDonors[index].status;
    String newStatus = currentStatus;
    String donorId = filteredDonors[index].id;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Update Donor Status"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Donor: ${filteredDonors[index].name}"),
                  SizedBox(height: 10),
                  Text("Current Status: $currentStatus"),
                  SizedBox(height: 20),
                  Text("New Status:"),
                  DropdownButton<String>(
                    value: newStatus,
                    isExpanded: true,
                    items: ["Active", "Pending", "Ineligible"]
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        newStatus = value!;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Updating donor status...")),
                );
                
                try {
                  await _donorService.updateDonorStatus(donorId, newStatus);
                  
                  // Refresh the donor list
                  _fetchDonors();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Donor status updated to $newStatus")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to update status: $e")),
                  );
                }
              },
              child: Text("Update"),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateDialog(int index) {
    Donor donor = filteredDonors[index];
    
    TextEditingController nameController = TextEditingController(text: donor.name);
    TextEditingController emailController = TextEditingController(text: donor.email);
    TextEditingController phoneController = TextEditingController(text: donor.contact);
    String selectedBloodGroup = donor.bloodGroup;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Update Donor Information"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: "Name"),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(labelText: "Email"),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(labelText: "Phone"),
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedBloodGroup,
                      decoration: InputDecoration(labelText: "Blood Group"),
                      items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                          .map((bloodGroup) => DropdownMenuItem(
                                value: bloodGroup,
                                child: Text(bloodGroup),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedBloodGroup = value!;
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Updating donor information...")),
                );
                
                try {
                  await _donorService.updateDonor(
                    donor.id,
                    {
                      'name': nameController.text,
                      'email': emailController.text,
                      'phone': phoneController.text,
                      'bloodGroup': selectedBloodGroup,
                    },
                  );
                  
                  // Refresh the donor list
                  _fetchDonors();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Donor information updated successfully")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to update donor: $e")),
                  );
                }
              },
              child: Text("Update"),
            ),
          ],
        );
      },
    );
  }

  void _onMenuSelected(String option, int index) async {
    if (option == "Update") {
      _showUpdateDialog(index);
    } else if (option == "Delete") {
      try {
        final donorId = filteredDonors[index].id;
        
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Deleting donor...")),
        );
        
        await _donorService.deleteDonor(donorId);
        
        // Refresh the donor list
        _fetchDonors();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Donor deleted successfully")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete donor: $e")),
        );
      }
    } else if (option == "Change Status") {
      _showStatusUpdateDialog(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Filter Donors",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: _fetchDonors,
                      tooltip: 'Refresh',
                      color: Colors.red.shade700,
                    ),
                  ],
                ),
                 
                SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search by name, ID or blood group",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: _filterDonors,
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedBloodType,
                        decoration: InputDecoration(
                          labelText: "Blood Type",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                        items: bloodTypes
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedBloodType = value!;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: InputDecoration(
                          labelText: "Status",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                        items: statusOptions
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value!;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                      
                  ],
                ),
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredDonors.isEmpty
                    ? Center(child: Text("No donors found"))
                    : ListView.builder(
                        itemCount: filteredDonors.length,
                        itemBuilder: (context, index) {
                          final donor = filteredDonors[index];
                          return DonorListTile(
                            donor: donor,
                            onMenuSelected: (option) => _onMenuSelected(option, index),
                          );
                        },
                      ),
          ),
        ],
      ),
     
    );
  }
}

// Custom widget for donor list item
class DonorListTile extends StatelessWidget {
  final Donor donor;
  final Function(String) onMenuSelected;

  const DonorListTile({
    Key? key,
    required this.donor,
    required this.onMenuSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getBloodGroupColor(donor.bloodGroup),
          child: Text(
            donor.bloodGroup,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              donor.name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(donor.status),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                donor.status,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text("ID: ${donor.donorId}"),
            Text("Last Donation: ${donor.lastDonation}"),
            Text("Contact: ${donor.contact}"),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: onMenuSelected,
          itemBuilder: (BuildContext context) => [
            PopupMenuItem(
              value: "Update",
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text("Update"),
                ],
              ),
            ),
            PopupMenuItem(
              value: "Change Status",
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, size: 18),
                  SizedBox(width: 8),
                  Text("Change Status"),
                ],
              ),
            ),
            PopupMenuItem(
              value: "Delete",
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Text("Delete", style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        isThreeLine: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Color _getBloodGroupColor(String bloodGroup) {
    switch (bloodGroup) {
      case 'A+':
        return Colors.red.shade700;
      case 'A-':
        return Colors.red.shade500;
      case 'B+':
        return Colors.blue.shade700;
      case 'B-':
        return Colors.blue.shade500;
      case 'AB+':
        return Colors.purple.shade700;
      case 'AB-':
        return Colors.purple.shade500;
      case 'O+':
        return Colors.green.shade700;
      case 'O-':
        return Colors.green.shade500;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Ineligible':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}



// Donor Detail Page
class DonorDetailPage extends StatefulWidget {
  final String donorId;

  const DonorDetailPage({Key? key, required this.donorId}) : super(key: key);

  @override
  _DonorDetailPageState createState() => _DonorDetailPageState();
}

class _DonorDetailPageState extends State<DonorDetailPage> {
  final DonorService _donorService = DonorService();
  bool isLoading = true;
  Donor? donor;

  @override
  void initState() {
    super.initState();
    _loadDonorDetails();
  }

  Future<void> _loadDonorDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      final donorData = await _donorService.getDonor(widget.donorId);
      setState(() {
        donor = donorData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading donor details: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Donor Details"),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit page
              if (donor != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditDonorPage(donor: donor!),
                  ),
                ).then((_) => _loadDonorDetails()); // Refresh details when returning
              }
            },
          ),
        ],
      ),
      body: isLoading || donor == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Donor Header
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: _getBloodGroupColor(donor!.bloodGroup),
                            child: Text(
                              donor!.bloodGroup,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            donor!.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(donor!.status),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              donor!.status,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text("Donor ID: ${donor!.donorId}"),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Contact Information
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Contact Information",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Divider(),
                          _buildInfoRow(Icons.email, "Email", donor!.email),
                          _buildInfoRow(Icons.phone, "Phone", donor!.contact),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Donation Information
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Donation Information",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Divider(),
                          _buildInfoRow(Icons.bloodtype, "Blood Group", donor!.bloodGroup),
                          _buildInfoRow(
                            Icons.calendar_today,
                            "Last Donation",
                            donor!.lastDonation,
                          ),
                          SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.add),
                              label: Text("Record New Donation"),
                              onPressed: () {
                                // Show dialog to record new donation
                                _showRecordDonationDialog();
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Action Buttons
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Actions",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Divider(),
                          SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.swap_horiz),
                              label: Text("Change Status"),
                              onPressed: () {
                                _showStatusChangeDialog();
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: Icon(Icons.delete, color: Colors.red),
                              label: Text(
                                "Delete Donor",
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () {
                                _showDeleteConfirmationDialog();
                              },
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade700),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRecordDonationDialog() {
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Record New Donation"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Select donation date:"),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        controller: TextEditingController(
                          text: "${selectedDate.toLocal()}".split(' ')[0],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                
                // Update last donation date
                try {
                  await _donorService.updateDonor(
                    donor!.id,
                    {'lastDonation': selectedDate.toIso8601String()},
                  );
                  
                  // Refresh donor details
                  _loadDonorDetails();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Donation recorded successfully")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to record donation: $e")),
                  );
                }
              },
              child: Text("Record"),
            ),
          ],
        );
      },
    );
  }

  void _showStatusChangeDialog() {
    String newStatus = donor!.status;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Change Donor Status"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Current Status: ${donor!.status}"),
                  SizedBox(height: 16),
                  Text("New Status:"),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: newStatus,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: ["Active", "Pending", "Ineligible"]
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        newStatus = value!;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                
                try {
                  await _donorService.updateDonorStatus(donor!.id, newStatus);
                  
                  // Refresh donor details
                  _loadDonorDetails();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Status updated successfully")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to update status: $e")),
                  );
                }
              },
              child: Text("Update"),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Donor"),
          content: Text(
            "Are you sure you want to delete ${donor!.name}? This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                
                try {
                  await _donorService.deleteDonor(donor!.id);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Donor deleted successfully")),
                  );
                  
                  // Return to donors list
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to delete donor: $e")),
                  );
                }
              },
              child: Text(
                "Delete",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getBloodGroupColor(String bloodGroup) {
    switch (bloodGroup) {
      case 'A+':
        return Colors.red.shade700;
      case 'A-':
        return Colors.red.shade500;
      case 'B+':
        return Colors.blue.shade700;
      case 'B-':
        return Colors.blue.shade500;
      case 'AB+':
        return Colors.purple.shade700;
      case 'AB-':
        return Colors.purple.shade500;
      case 'O+':
        return Colors.green.shade700;
      case 'O-':
        return Colors.green.shade500;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Ineligible':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Edit Donor Page
class EditDonorPage extends StatefulWidget {
  final Donor donor;

  const EditDonorPage({Key? key, required this.donor}) : super(key: key);

  @override
  _EditDonorPageState createState() => _EditDonorPageState();
}

class _EditDonorPageState extends State<EditDonorPage> {
  final _formKey = GlobalKey<FormState>();
  final DonorService _donorService = DonorService();
  
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late String selectedBloodGroup;
  DateTime? selectedLastDonationDate;
  
  bool isSubmitting = false;
  
  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.donor.name);
    emailController = TextEditingController(text: widget.donor.email);
    phoneController = TextEditingController(text: widget.donor.contact);
    selectedBloodGroup = widget.donor.bloodGroup;
    
    if (widget.donor.lastDonation != "No donation yet") {
      try {
        selectedLastDonationDate = DateTime.parse(widget.donor.lastDonation);
      } catch (e) {
        // Handle parsing error
      }
    }
  }
  
  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Donor"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person,  color: Colors.redAccent,),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter donor name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email Address",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email,color: Colors.redAccent,),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email address';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone, color: Colors.redAccent,),
                  
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedBloodGroup,
                decoration: InputDecoration(
                  labelText: "Blood Group",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.bloodtype, color: Colors.redAccent,),
                ),
                items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedBloodGroup = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select blood group';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedLastDonationDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedLastDonationDate = picked;
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: "Last Donation Date",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today, color: Colors.redAccent,),
                      suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.redAccent,),
                    ),
                    controller: TextEditingController(
                      text: selectedLastDonationDate != null
                          ? "${selectedLastDonationDate!.toLocal()}".split(' ')[0]
                          : '',
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _updateDonor,
                  child: isSubmitting
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Update Donor", style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateDonor() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isSubmitting = true;
      });

      try {
        // Create donor data for update
        Map<String, dynamic> donorData = {
          'name': nameController.text,
          'email': emailController.text,
          'phone': phoneController.text,
          'bloodGroup': selectedBloodGroup,
        };

        // Add lastDonation date if selected
        if (selectedLastDonationDate != null) {
          donorData['lastDonation'] = selectedLastDonationDate!.toIso8601String();
        }

        // Update donor
        await _donorService.updateDonor(widget.donor.id, donorData);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Donor updated successfully")),
        );
        
        Navigator.pop(context); // Return to previous screen
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating donor: $e")),
        );
      } finally {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }
}

// Implement Nearby Donors Page
class NearbyDonorsPage extends StatefulWidget {
  const NearbyDonorsPage({Key? key}) : super(key: key);

  @override
  _NearbyDonorsPageState createState() => _NearbyDonorsPageState();
}

class _NearbyDonorsPageState extends State<NearbyDonorsPage> {
  final DonorService _donorService = DonorService();
  List<Donor> nearbyDonors = [];
  bool isLoading = false;
  
  // Default location (could be user's current location in a real app)
  double latitude = 0.0;
  double longitude = 0.0;
  double searchRadius = 10.0; // kilometers
  String? selectedBloodGroup;
  
  @override
  void initState() {
    super.initState();
    // In a real app, you would get the user's current location
    // For now, we'll use placeholder values
    _getCurrentLocation();
  }
  
  Future<void> _getCurrentLocation() async {
    // In a real app, you would use a location plugin like geolocator
    // For this example, we'll use placeholder values
    setState(() {
      latitude = 37.7749; // Example: San Francisco
      longitude = -122.4194;
    });
    
    // Once we have location, search for nearby donors
    _searchNearbyDonors();
  }
  
  Future<void> _searchNearbyDonors() async {
    if (latitude == 0.0 && longitude == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location not available")),
      );
      return;
    }
    
    setState(() {
      isLoading = true;
    });
    
    try {
      final fetchedDonors = await _donorService.findNearbyDonors(
        latitude: latitude,
        longitude: longitude,
        radius: searchRadius,
        bloodGroup: selectedBloodGroup,
      );
      
      setState(() {
        nearbyDonors = fetchedDonors;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to find nearby donors: $e")),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nearby Donors"),
      ),
      body: Column(
        children: [
          // Search Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Find Donors Nearby",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedBloodGroup,
                        decoration: InputDecoration(
                          labelText: "Blood Type",
                          border: OutlineInputBorder(),
                        ),
                        items: [null, 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type ?? "All Blood Types"),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedBloodGroup = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: searchRadius.toString(),
                        decoration: InputDecoration(
                          labelText: "Radius (km)",
                          border: OutlineInputBorder(),
                          suffixText: "km",
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            searchRadius = double.tryParse(value) ?? 10.0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _searchNearbyDonors,
                    child: Text("Search"),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(),
          // Results
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : nearbyDonors.isEmpty
                    ? Center(child: Text("No donors found nearby"))
                    : ListView.builder(
                        itemCount: nearbyDonors.length,
                        itemBuilder: (context, index) {
                          final donor = nearbyDonors[index];
                          return DonorListTile(
                            donor: donor,
                            onMenuSelected: (option) {
                              // Handle menu options for nearby donors
                              if (option == "View Details") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DonorDetailPage(donorId: donor.id),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}