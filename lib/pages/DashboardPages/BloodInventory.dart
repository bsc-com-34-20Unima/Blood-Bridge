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
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BloodInventoryPage()),
            );
          },
          child: Text("View Blood Inventory"),
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
      // appBar: AppBar(
      //   // title: Text("Blood Inventory"),
      //   backgroundColor: Colors.redAccent,
      // ),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: ListView.builder(
          itemCount: bloodInventoryList.length,
          itemBuilder: (context, index) {
            final bloodInventory = bloodInventoryList[index];
            Color statusColor = bloodInventory.status == "Sufficient"
                ? Colors.green
                : bloodInventory.status == "Near Critical"
                    ? Colors.orange
                    : Colors.red;
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
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'Update') {
                              _updateBloodUnits(index);
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
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Units: ${bloodInventory.availableUnits}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          "Status: ",
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          bloodInventory.status,
                          style: TextStyle(
                            fontSize: 14,
                            color: statusColor,
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
    );
  }
}
