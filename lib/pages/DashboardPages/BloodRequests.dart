import 'package:flutter/material.dart';

// Model for a blood request
class BloodRequest {
  final String bloodType;
  final int quantity;
  final double radius;
  final DateTime timestamp;

  BloodRequest({
    required this.bloodType,
    required this.quantity,
    required this.radius,
    required this.timestamp,
  });
}

class BloodRequests extends StatefulWidget {
  const BloodRequests({super.key});

  @override
  _BloodRequestPageState createState() => _BloodRequestPageState();
}

class _BloodRequestPageState extends State<BloodRequests> {
  final _formKey = GlobalKey<FormState>();
  String? _bloodType;
  String? _radius;
  String? _quantity;

  final List<String> _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  // List to track submitted blood requests
  final List<BloodRequest> _submittedRequests = [];

  void _submitRequest() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Create a new blood request from the form values
      final newRequest = BloodRequest(
        bloodType: _bloodType!,
        quantity: int.parse(_quantity!),
        radius: double.parse(_radius!),
        timestamp: DateTime.now(),
      );

      setState(() {
        _submittedRequests.add(newRequest);
      });

      // Show confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Blood request submitted successfully!')),
      );

      // Optionally, reset the form after submission
      _formKey.currentState!.reset();
      setState(() {
        _bloodType = null;
        _quantity = null;
        _radius = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Blood Request Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField(
                    decoration: InputDecoration(
                      labelText: 'Blood Type',
                      border: OutlineInputBorder(),
                    ),
                    items: _bloodTypes
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() {
                      _bloodType = value as String?;
                    }),
                    validator: (value) =>
                        value == null ? 'Please select a blood type' : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Quantity (in units)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => _quantity = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the quantity';
                      }
                      if (int.tryParse(value) == null || int.parse(value) <= 0) {
                        return 'Enter a valid quantity';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Radius (in km)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => _radius = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the radius';
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Enter a valid radius';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red
                    ),
                    child: Text('Submit Request', style: TextStyle(color: Colors.white),),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Divider(),
            // Submitted Blood Requests Section
            Text(
              'Submitted Blood Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            _submittedRequests.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'No blood requests submitted yet.',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _submittedRequests.length,
                    itemBuilder: (context, index) {
                      final request = _submittedRequests[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                              '${request.bloodType} - ${request.quantity} units'),
                          subtitle: Text(
                              'Radius: ${request.radius} km\nSubmitted on: ${request.timestamp.toLocal().toString().split('.')[0]}'),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
