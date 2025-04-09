import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bloodbridge/services/bloodrequest_service.dart';

class BloodRequests extends StatefulWidget {
  const BloodRequests({super.key});

  @override
  State<BloodRequests> createState() => _BloodRequestsState();
}

class _BloodRequestsState extends State<BloodRequests> {
  final _requestService = BloodRequestService();
  final _distanceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String _selectedBloodType = 'A+';
  bool _isLoading = false;
  bool _broadcastAll = false;  // New flag for broadcasting requests
  
  // Map Flutter blood types to API blood types if needed
  final Map<String, String> _bloodTypeMapping = {
    'A+': 'A_POSITIVE',
    'A-': 'A_NEGATIVE',
    'B+': 'B_POSITIVE',
    'B-': 'B_NEGATIVE',
    'AB+': 'AB_POSITIVE',
    'AB-': 'AB_NEGATIVE',
    'O+': 'O_POSITIVE',
    'O-': 'O_NEGATIVE',
  };

  // Blood type color mapping for visual enhancement
  final Map<String, Color> _bloodTypeColors = {
    'A+': Colors.red.shade100,
    'A-': Colors.red.shade200,
    'B+': Colors.blue.shade100,
    'B-': Colors.blue.shade200,
    'AB+': Colors.green.shade100,
    'AB-': Colors.green.shade200,
    'O+': Colors.orange.shade100,
    'O-': Colors.orange.shade200,
  };

  @override
  Widget build(BuildContext context) {
    // Build method remains the same
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Donor Request'),
        centerTitle: true,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Blood Type Dropdown with Visual Enhancement
                DropdownButtonFormField<String>(
                  value: _selectedBloodType,
                  decoration: InputDecoration(
                    labelText: 'Blood Type Needed',
                    filled: true,
                    fillColor: _bloodTypeColors[_selectedBloodType],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _bloodTypeColors.keys
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(
                              type,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedBloodType = value!),
                ),
                const SizedBox(height: 20),

                // Broadcast Option
                CheckboxListTile(
                  value: _broadcastAll,
                  onChanged: (value) {
                    setState(() {
                      _broadcastAll = value!;
                      // Clear the blood type selection if broadcasting
                      if (_broadcastAll) {
                        _selectedBloodType = '';
                      }
                    });
                  },
                  title: const Text('Broadcast to all donors'),
                  subtitle: const Text('If selected, the request will be sent to all donors, regardless of blood type.'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 20),

                // Distance Input with Improved Validation
                TextFormField(
                  controller: _distanceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Maximum Distance',
                    hintText: 'Enter distance in kilometers',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    suffixText: 'km',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a distance';
                    }
                    final distance = double.tryParse(value);
                    if (distance == null || distance <= 0) {
                      return 'Please enter a valid distance';
                    }
                    if (distance > 500) {
                      return 'Distance should be less than 500 km';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Submit Button with Loading State
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _sendRequests,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Find Matching Donors',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendRequests() async {
    // Added form validation before sending requests
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Convert Firebase UID to your hospital ID format if needed
      String hospitalId = FirebaseAuth.instance.currentUser!.uid;
      
      // Get API-compatible blood type, or use null if broadcasting
      String? apiBloodType = _broadcastAll ? null : _bloodTypeMapping[_selectedBloodType] ?? _selectedBloodType;
      
      final results = await _requestService.requestDonorsByDistance(
        hospitalId: hospitalId,
        requestedBloodType: apiBloodType,
        maxDistanceKm: double.parse(_distanceController.text),
        broadcastAll: _broadcastAll, // Pass broadcast flag
      );
      
      // More descriptive success message with count of donors notified
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${results.length} blood donor requests sent for $_selectedBloodType blood type!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // More detailed error handling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send requests: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }
}
