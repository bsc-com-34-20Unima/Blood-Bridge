import 'package:flutter/material.dart';
import 'package:bloodbridge/services/bloodrequest_service.dart';

class BloodRequests extends StatefulWidget {
  const BloodRequests({super.key});

  @override
  State<BloodRequests> createState() => _BloodRequestsState();
}

class _BloodRequestsState extends State<BloodRequests> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _requestService = BloodRequestService();
  final _distanceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1'); // Default quantity
  final _formKey = GlobalKey<FormState>();
  
  String _selectedBloodType = 'A+';
  bool _isLoading = false;
  bool _broadcastAll = false;  // Flag for broadcasting requests
  List<dynamic> _activeRequests = [];
  bool _loadingRequests = false;
  
  // Map Flutter blood types to API blood types if needed
  final Map<String, String> _bloodTypeMapping = {
    'A+': 'A+',  
    'A-': 'A-',
    'B+': 'B+',
    'B-': 'B-',
    'AB+': 'AB+',
    'AB-': 'AB-',
    'O+': 'O+',
    'O-': 'O-',
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
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchActiveRequests();
  }

  // Fetch active blood requests
  Future<void> _fetchActiveRequests() async {
    setState(() => _loadingRequests = true);
    try {
      final requests = await _requestService.getHospitalRequests();
      setState(() {
        _activeRequests = requests;
        _loadingRequests = false;
      });
    } catch (e) {
      setState(() => _loadingRequests = false);
      _showError('Failed to load active requests: ${e.toString()}');
    }
  }

  // Helper to show error messages
  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {},
          textColor: Colors.white,
        ),
      ),
    );
  }
  // Helper to show success messages
  void _showSuccess(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(''),
        centerTitle: true,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'New Request', icon: Icon(Icons.add_circle_outline)),
            Tab(text: 'Active Requests', icon: Icon(Icons.list)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // New Request Tab
          _buildNewRequestTab(),
          
          // Active Requests Tab
          _buildActiveRequestsTab(),
        ],
      ),
    );
  }

  Widget _buildNewRequestTab() {
    return SingleChildScrollView(
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
                  // Add hint or helper text to indicate why it's disabled
                  helperText: _broadcastAll 
                      ? 'Blood type selection disabled when broadcasting to all donors' 
                      : null,
                ),
                items: _bloodTypeColors.keys
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            type,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ))
                    .toList(),
                // Disable dropdown when broadcasting to all
                onChanged: _broadcastAll 
                    ? null 
                    : (value) => setState(() => _selectedBloodType = value!),
              ),
              const SizedBox(height: 20),

              // Broadcast Option
              CheckboxListTile(
                value: _broadcastAll,
                onChanged: (value) {
                  setState(() {
                    _broadcastAll = value!;
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
              const SizedBox(height: 20),

              // Quantity Input 
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity Needed',
                  hintText: 'Enter number of units needed',
                  prefixIcon: const Icon(Icons.bloodtype_outlined),
                  suffixText: 'units',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a quantity';
                  }
                  final quantity = int.tryParse(value);
                  if (quantity == null || quantity <= 0) {
                    return 'Please enter a valid quantity';
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size(200, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Find matching donors',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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

  Widget _buildActiveRequestsTab() {
    return _loadingRequests
        ? const Center(child: CircularProgressIndicator())
        : _activeRequests.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No active blood requests',
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _fetchActiveRequests,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _fetchActiveRequests,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _activeRequests.length,
                  itemBuilder: (context, index) {
                    final request = _activeRequests[index];
                    return _buildRequestCard(request);
                  },
                ),
              );
  }

  Widget _buildRequestCard(dynamic request) {
    // Convert API blood type format back to display format
    String displayBloodType = _bloodTypeMapping.entries
        .firstWhere(
          (entry) => entry.value == request['bloodType'],
          orElse: () => const MapEntry('All', 'ALL'),
        )
        .key;

    // Handle the case when the blood request was for all types
    if (request['bloodType'] == null || request['bloodType'] == 'ALL') {
      displayBloodType = 'All';
    }

    Color bloodTypeColor = _bloodTypeColors[displayBloodType] ?? Colors.grey.shade200;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: bloodTypeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    displayBloodType,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    request['id'] != null ? 'Request #${request['id']}' : 'New Request',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request['status']),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    request['status'] ?? 'ACTIVE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
                Icons.location_on, 'Radius: ${request['radius']?.toString() ?? '?'} km'),
            if (request['quantity'] != null)
              _buildInfoRow(
                Icons.format_list_numbered, 'Quantity: ${request['quantity']?.toString() ?? '1'} units'),
            if (request['donorsNotified'] != null)
              _buildInfoRow(
                  Icons.people, 'Donors notified: ${request['donorsNotified']?.toString() ?? '0'}'),
            if (request['createdAt'] != null)
              _buildInfoRow(Icons.date_range, 'Created: ${_formatDate(request['createdAt'])}'),
            const SizedBox(height: 12),
            if (request['status'] == 'ACTIVE' || request['status'] == 'PENDING')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _cancelRequest(request['id']),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    label: const Text('Cancel Request', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.blue;
      case 'PENDING':
        return Colors.orange;
      case 'FULFILLED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel Request'),
          content: const Text('Are you sure you want to cancel this blood request?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Cancelling request...'),
              ],
            ),
          ),
        );
        
        // Cancel the request
        final success = await _requestService.cancelRequest(requestId);
        
        // Close loading dialog
        if (mounted) Navigator.of(context).pop();
        
        if (success) {
          _showSuccess('Blood request cancelled successfully');
          // Refresh the active requests list
          _fetchActiveRequests();
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // Close loading dialog if open
      _showError('Failed to cancel request: ${e.toString()}');
    }
  }

  Future<void> _sendRequests() async {
    // Added form validation before sending requests
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Get API-compatible blood type, or use 'ALL' if broadcasting
      String bloodType = _broadcastAll ? 'ALL' : _bloodTypeMapping[_selectedBloodType]!;
      
      final results = await _requestService.requestDonorsByDistance(
        bloodType: bloodType,
        radius: double.parse(_distanceController.text),
        quantity: int.parse(_quantityController.text),
        broadcastAll: _broadcastAll,
      );
      
      // More descriptive success message with count of donors notified
      _showSuccess(
        _broadcastAll 
          ? '${results.length} blood donor requests sent to all blood types!' 
          : '${results.length} blood donor requests sent for $_selectedBloodType blood type!'
      );
      
      // Reset form or navigate to active requests
      _distanceController.clear();
      _quantityController.text = '1'; // Reset to default quantity
      
      // Refresh data
      _fetchActiveRequests();
      
      // Switch to the active requests tab using our tabController
      _tabController.animateTo(1);
      
    } catch (e) {
      // More detailed error handling
      _showError('Failed to send requests: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _quantityController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}