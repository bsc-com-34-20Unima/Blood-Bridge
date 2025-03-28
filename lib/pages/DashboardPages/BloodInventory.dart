import 'package:flutter/material.dart';

void main() {
  runApp(BloodBridgeApp());
}

class BloodBridgeApp extends StatelessWidget {
  const BloodBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blood Bridge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blood Bridge'),
        centerTitle: true,
      ),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BloodInventoryPage()),
            );
          },
          child: Text(
            "View Blood Inventory",
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}

class BloodInventory {
  final String bloodGroup;
  int availableUnits;
  String status;

  BloodInventory({
    required this.bloodGroup,
    required this.availableUnits,
    required this.status,
  });

  void updateUnits(int newUnits) {
    availableUnits = newUnits;
    if (availableUnits > 5) {
      status = "Sufficient";
    } else if (availableUnits > 2) {
      status = "Near Critical";
    } else {
      status = "Critical Shortage";
    }
  }
}

class BloodInventoryPage extends StatefulWidget {
  const BloodInventoryPage({super.key});

  @override
  _BloodInventoryPageState createState() => _BloodInventoryPageState();
}

class _BloodInventoryPageState extends State<BloodInventoryPage> {
  List<BloodInventory> bloodInventoryList = [
    BloodInventory(bloodGroup: "A+", availableUnits: 10, status: "Sufficient"),
    BloodInventory(bloodGroup: "O-", availableUnits: 1, status: "Critical Shortage"),
    BloodInventory(bloodGroup: "B+", availableUnits: 5, status: "Near Critical"),
    BloodInventory(bloodGroup: "AB-", availableUnits: 0, status: "Critical Shortage"),
    BloodInventory(bloodGroup: "A-", availableUnits: 3, status: "Near Critical"),
    BloodInventory(bloodGroup: "O+", availableUnits: 8, status: "Sufficient"),
    BloodInventory(bloodGroup: "B-", availableUnits: 2, status: "Critical Shortage"),
    BloodInventory(bloodGroup: "AB+", availableUnits: 6, status: "Sufficient"),
  ];

  /// Returns a priority value based on status.
  /// Lower numbers indicate higher urgency.
  int _getStatusPriority(String status) {
    switch (status) {
      case "Critical Shortage":
        return 0;
      case "Near Critical":
        return 1;
      case "Sufficient":
        return 2;
      default:
        return 3;
    }
  }

  void _updateBloodUnits(int index) {
    TextEditingController unitsController = TextEditingController(
      text: bloodInventoryList[index].availableUnits.toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Update ${bloodInventoryList[index].bloodGroup} Units"),
          content: TextField(
            controller: unitsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Available Units",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  int updatedUnits = int.tryParse(unitsController.text) ?? 0;
                  bloodInventoryList[index].updateUnits(updatedUnits);
                });
                Navigator.of(context).pop();
              },
              child: Text("Update"),
            ),
          ],
        );
      },
    );
  }

  Color getStatusColor(String status) {
    if (status == "Sufficient") return Colors.green;
    if (status == "Near Critical") return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    // Create a sorted copy of the list based on the urgency of the status.
    List<BloodInventory> sortedList = List.from(bloodInventoryList);
    sortedList.sort((a, b) => _getStatusPriority(a.status).compareTo(_getStatusPriority(b.status)));

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(10),
        child: ListView.builder(
          itemCount: sortedList.length,
          itemBuilder: (context, index) {
            final bloodInventory = sortedList[index];
            Color statusColor = getStatusColor(bloodInventory.status);

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 5),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Icon(Icons.bloodtype, color: statusColor),
                ),
                title: Text(
                  bloodInventory.bloodGroup,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(
                      "Units: ${bloodInventory.availableUnits}",
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          "Status: ",
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          bloodInventory.status,
                          style: TextStyle(
                            fontSize: 14,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'Update') {
                      // Find the actual index in the original list based on blood group.
                      int originalIndex = bloodInventoryList.indexWhere(
                          (item) => item.bloodGroup == bloodInventory.bloodGroup);
                      _updateBloodUnits(originalIndex);
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return {'Update'}.map((String choice) {
                      return PopupMenuItem<String>(
                        value: choice,
                        child: Text(choice),
                      );
                    }).toList();
                  },
                  icon: Icon(Icons.more_vert),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
