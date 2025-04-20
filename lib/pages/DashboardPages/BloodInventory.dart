import 'package:flutter/material.dart';
import 'api_service.dart';

class BloodInventory {
  final int id;
  final String bloodGroup;
  int availableUnits;
  String status;

  BloodInventory({
    required this.id,
    required this.bloodGroup,
    required this.availableUnits,
    required this.status,
  });

  factory BloodInventory.fromJson(Map<String, dynamic> json) {
    return BloodInventory(
      id: json['id'],
      bloodGroup: json['bloodGroup'],
      availableUnits: json['availableUnits'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bloodGroup': bloodGroup,
      'availableUnits': availableUnits,
      'status': status,
    };
  }
}

class BloodInventoryPage extends StatefulWidget {
  @override
  _BloodInventoryPageState createState() => _BloodInventoryPageState();
}

class _BloodInventoryPageState extends State<BloodInventoryPage> {
  late Future<List<BloodInventory>> _inventoryFuture;
  final ApiService _apiService = ApiService();
  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void initState() {
    super.initState();
    _inventoryFuture = _apiService.fetchInventory();
  }

  Future<void> _refreshInventory() async {
    setState(() {
      _inventoryFuture = _apiService.fetchInventory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: FutureBuilder<List<BloodInventory>>(
        future: _inventoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Create a map of existing inventory items for quick lookup
          final existingItems = {
            for (var item in snapshot.data ?? []) item.bloodGroup: item
          };

          // Create a list that includes all blood groups
          final List displayList = _bloodGroups.map((group) {
            return existingItems[group] ??
                BloodInventory(
                  id: -1, // Temporary ID for items not in the database
                  bloodGroup: group,
                  availableUnits: 0,
                  status: 'Critical Shortage',
                );
          }).toList();

          // Sort by available units
          displayList.sort((a, b) => a.availableUnits.compareTo(b.availableUnits));

          return RefreshIndicator(
            onRefresh: _refreshInventory,
            child: ListView.builder(
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final bloodInventory = displayList[index];
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
                        Text("Units: ${bloodInventory.availableUnits}", 
                            style: TextStyle(fontSize: 16)),
                        Text(
                          "Status: ${bloodInventory.status}",
                          style: TextStyle(
                            fontSize: 14,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'Update') {
                          _updateBloodUnitsDialog(context, bloodInventory);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'Update', child: Text('Update')),
                      ],
                      icon: Icon(Icons.more_vert),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNewBloodGroupDialog(context),
        child: Icon(Icons.add),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _updateBloodUnitsDialog(BuildContext context, BloodInventory inventory) {
    TextEditingController controller =
        TextEditingController(text: inventory.availableUnits.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update ${inventory.bloodGroup} Units'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Available Units",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              int newUnits = int.tryParse(controller.text) ?? inventory.availableUnits;
              
              if (inventory.id == -1) {
                // This is a new blood group not in the database yet
                await _apiService.createInventory(
                  bloodGroup: inventory.bloodGroup,
                  availableUnits: newUnits,
                );
              } else {
                // Existing blood group
                await _apiService.updateInventory(inventory.id, newUnits);
              }

              _refreshInventory();
              Navigator.pop(context);
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _addNewBloodGroupDialog(BuildContext context) {
    String? selectedGroup;
    TextEditingController unitsController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Blood Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedGroup,
              decoration: InputDecoration(
                labelText: 'Blood Group',
                border: OutlineInputBorder(),
              ),
              items: _bloodGroups.map((String group) {
                return DropdownMenuItem<String>(
                  value: group,
                  child: Text(group),
                );
              }).toList(),
              onChanged: (String? newValue) {
                selectedGroup = newValue;
              },
              validator: (value) =>
                  value == null ? 'Please select a blood group' : null,
            ),
            SizedBox(height: 16),
            TextField(
              controller: unitsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Available Units",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedGroup != null) {
                await _apiService.createInventory(
                  bloodGroup: selectedGroup!,
                  availableUnits: int.tryParse(unitsController.text) ?? 0,
                );
                _refreshInventory();
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "Critical Shortage":
        return Colors.red;
      case "Near Critical":
        return Colors.orange;
      case "Sufficient":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}