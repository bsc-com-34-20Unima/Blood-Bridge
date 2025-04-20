import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(BloodBridgeApp());
}

class BloodBridgeApp extends StatelessWidget {
  const BloodBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DonorsPage(),
    );
  }
}

class Donor {
  final String id;
  final String name;
  final String bloodGroup;
  final String lastDonation;
  final String phone;

  Donor({
    required this.id,
    required this.name,
    required this.bloodGroup,
    required this.lastDonation,
    required this.phone,
  });

  factory Donor.fromJson(Map<String, dynamic> json) {
    return Donor(
      id: json['id'],
      name: json['name'],
      bloodGroup: json['bloodGroup'],
      lastDonation: json['lastDonation'] ?? 'Not available',
      phone: json['phone'] ?? 'Not provided',
    );
  }
}

class DonorsPage extends StatefulWidget {
  const DonorsPage({super.key});

  @override
  _DonorsPageState createState() => _DonorsPageState();
}

class _DonorsPageState extends State<DonorsPage> {
  List<Donor> donors = [];
  List<Donor> filteredDonors = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchDonors();
  }

  Future<void> _fetchDonors() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.137.131:3005/donors'), // Replace with your API endpoint
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          donors = data.map((json) => Donor.fromJson(json)).toList();
          filteredDonors = donors;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load donors: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching donors: $e';
        isLoading = false;
      });
    }
  }

  void _filterDonors(String query) {
    setState(() {
      filteredDonors = donors
          .where((donor) =>
              donor.name.toLowerCase().contains(query.toLowerCase()) ||
              donor.bloodGroup.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            TextField(
              onChanged: _filterDonors,
              decoration: InputDecoration(
                labelText: "Search Donors",
                hintText: "Search by name or blood group",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage.isNotEmpty)
              Center(child: Text(errorMessage))
            else if (filteredDonors.isEmpty)
              const Center(child: Text('No donors found'))
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchDonors,
                  child: ListView.builder(
                    itemCount: filteredDonors.length,
                    itemBuilder: (context, index) {
                      final donor = filteredDonors[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    donor.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.red,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      donor.bloodGroup,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 5),
                                  Text(
                                    "Last Donation: ${donor.lastDonation}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                                  const SizedBox(width: 5),
                                  Text(
                                    donor.phone,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}