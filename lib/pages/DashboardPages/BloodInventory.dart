import 'package:flutter/material.dart';

void main() {
  runApp(BloodBridgeApp());
}

class BloodBridgeApp extends StatelessWidget {
  const BloodBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BloodInventoryPage(),
    );
  }
}

class BloodInventory {
  final String bloodGroup;
  int availableUnits; // Mutable now
  String status; // "Sufficient" or "Critical Shortage"
  
  BloodInventory({
    required this.bloodGroup,
    required this.availableUnits,
    required this.status,
  });

  void updateUnits(int newUnits) {
    availableUnits = newUnits;
    status = availableUnits > 0 ? "Sufficient" : "Critical Shortage";
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
    BloodInventory(bloodGroup: "B+", availableUnits: 5, status: "Sufficient"),
    BloodInventory(bloodGroup: "AB-", availableUnits: 0, status: "Critical Shortage"),
    BloodInventory(bloodGroup: "A-", availableUnits: 3, status: "Sufficient"),
    BloodInventory(bloodGroup: "O+", availableUnits: 8, status: "Sufficient"),
    BloodInventory(bloodGroup: "B-", availableUnits: 2, status: "Critical Shortage"),
    BloodInventory(bloodGroup: "AB+", availableUnits: 6, status: "Sufficient"),
  ];

  void _updateBloodUnits(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController unitsController = TextEditingController(
          text: bloodInventoryList[index].availableUnits.toString(),
        );
        return AlertDialog(
          title: Text("Update Units for ${bloodInventoryList[index].bloodGroup}"),
          content: TextField(
            controller: unitsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Available Units"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  int updatedUnits = int.tryParse(unitsController.text) ?? 0;
                  bloodInventoryList[index].updateUnits(updatedUnits);
                });
                Navigator.of(context).pop();
              },
              child: Text("Update"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
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
        child: ListView.builder(
          itemCount: bloodInventoryList.length,
          itemBuilder: (context, index) {
            final bloodInventory = bloodInventoryList[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 3,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          bloodInventory.bloodGroup,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Units: ${bloodInventory.availableUnits}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              "Status: ${bloodInventory.status}",
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    // Display the status symbol
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          bloodInventory.status == "Sufficient"
                              ? Icons.check_circle
                              : Icons.warning,
                          color: bloodInventory.status == "Sufficient"
                              ? Colors.green
                              : Colors.red,
                          size: 30,
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    // Three dots menu for Update (no delete option)
                    Align(
                      alignment: Alignment.centerRight,
                      child: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'Update') {
                            _updateBloodUnits(index);
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return {'Update'}
                              .map((String choice) {
                            return PopupMenuItem<String>(
                              value: choice,
                              child: Text(choice),
                            );
                          }).toList();
                        },
                        icon: Icon(Icons.more_vert),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
