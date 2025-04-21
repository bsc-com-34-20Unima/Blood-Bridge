import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting dates

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
  String name;
  String bloodGroup;
  String lastDonation;
  String phone;

  Donor({
    required this.name,
    required this.bloodGroup,
    required this.lastDonation,
    required this.phone,
  });
}

class DonorsPage extends StatefulWidget {
  const DonorsPage({super.key});

  @override
  _DonorsPageState createState() => _DonorsPageState();
}

class _DonorsPageState extends State<DonorsPage> {
  List<Donor> donors = [
    Donor(name: "chisomo Doe", bloodGroup: "A+", lastDonation: "05 Jan 2025", phone: "0999123456"),
    Donor(name: "Jane Smith", bloodGroup: "O-", lastDonation: "12 Dec 2024", phone: "0888765432"),
    Donor(name: "Michael usi", bloodGroup: "B+", lastDonation: "20 Nov 2024", phone: "0977456789"),
    Donor(name: "Lorrita juta ", bloodGroup: "AB-", lastDonation: "10 Oct 2024", phone: "0999345678"),
  ];

  List<Donor> filteredDonors = [];

  @override
  void initState() {
    super.initState();
    filteredDonors = donors;
  }

  void _filterDonors(String query) {
    setState(() {
      filteredDonors = donors
          .where((donor) => donor.bloodGroup.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _onMenuSelected(String option, int index) {
    if (option == "Update") {
      _showUpdateDialog(index);
    } else if (option == "Delete") {
      setState(() {
        donors.removeAt(index);
        filteredDonors = List.from(donors);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Donor deleted")),
      );
    }
  }

  void _showUpdateDialog(int index) {
    TextEditingController nameController = TextEditingController(text: donors[index].name);
    TextEditingController bloodGroupController = TextEditingController(text: donors[index].bloodGroup);
    TextEditingController phoneController = TextEditingController(text: donors[index].phone);

    DateTime? selectedDate = DateFormat("dd MMM yyyy").parse(donors[index].lastDonation);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Update Donor"),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: "Name"),
                  ),
                  TextField(
                    controller: bloodGroupController,
                    decoration: InputDecoration(labelText: "Blood Group"),
                  ),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(labelText: "Phone Number"),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setStateDialog(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Last Donation Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        selectedDate != null
                            ? DateFormat('dd MMM yyyy').format(selectedDate!)
                            : 'Select Date',
                        style: TextStyle(fontSize: 16),
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
              onPressed: () {
                setState(() {
                  donors[index].name = nameController.text;
                  donors[index].bloodGroup = bloodGroupController.text;
                  donors[index].phone = phoneController.text;
                  donors[index].lastDonation =
                      selectedDate != null ? DateFormat('dd MMM yyyy').format(selectedDate!) : donors[index].lastDonation;
                  filteredDonors = List.from(donors);
                });
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            TextField(
              onChanged: _filterDonors,
              decoration: InputDecoration(
                labelText: "Search by Blood Group",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: filteredDonors.length,
                itemBuilder: (context, index) {
                  final donor = filteredDonors[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: EdgeInsets.all(15),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  donor.bloodGroup,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  donor.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  "Phone: ${donor.phone}",
                                  style: TextStyle(fontSize: 14),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  "Last Donation Date: ${donor.lastDonation}",
                                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) => _onMenuSelected(value, index),
                            itemBuilder: (context) => [
                              PopupMenuItem(value: "Update", child: Text("Update")),
                              PopupMenuItem(value: "Delete", child: Text("Delete")),
                            ],
                            icon: Icon(Icons.more_vert),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}