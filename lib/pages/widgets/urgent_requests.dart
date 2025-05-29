import 'package:flutter/material.dart';
import 'package:bloodbridge/services/bloodrequest_service.dart';
import 'package:bloodbridge/services/auth_service.dart';

class UrgentRequests extends StatefulWidget {
  const UrgentRequests({super.key});

  @override
  State<UrgentRequests> createState() => _UrgentRequestsState();
}

class _UrgentRequestsState extends State<UrgentRequests> {
  final _requestService = BloodRequestService();
  final _authService = AuthService();
  List<dynamic> _activeRequests = [];
  bool _isLoading = true;
  String? _donorId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = await _authService.getUserId();
      if (userId != null) {
        setState(() {
          _donorId = userId;
        });
        _fetchActiveRequests();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load user data: ${e.toString()}');
    }
  }

  Future<void> _fetchActiveRequests() async {
    if (_donorId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final requests = await _requestService.getDonorRequests();
      
      requests.sort((a, b) {
        DateTime dateA = DateTime.parse(a['createdAt'] ?? '2000-01-01');
        DateTime dateB = DateTime.parse(b['createdAt'] ?? '2000-01-01');
        return dateB.compareTo(dateA);
      });
      
      // Include requests that are ACTIVE, PENDING, or PARTIALLY_FULFILLED
      final activeRequests = requests.where((request) => 
        request['status'] == 'ACTIVE' || 
        request['status'] == 'PENDING' ||
        request['status'] == 'PARTIALLY_FULFILLED').toList();
      
      setState(() {
        _activeRequests = activeRequests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load blood requests: ${e.toString()}');
    }
  }

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

  Future<void> _respondToRequest(String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Response'),
        content: const Text(
          'Are you sure you want to respond to this blood request? '
          'The hospital will be notified of your availability.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Sending response...'),
              ],
            ),
          ),
        );
        
        final success = await _requestService.respondToRequest(requestId);
        
        if (mounted) Navigator.of(context).pop();
        
        if (success) {
          _showSuccess('Thank you! The hospital has been notified of your availability.');
          
          // Update the local state - the request might become PARTIALLY_FULFILLED
          // instead of being removed entirely
          setState(() {
            int requestIndex = _activeRequests.indexWhere((req) => req['id'] == requestId);
            if (requestIndex != -1) {
              // Mark that this donor has responded to this request
              _activeRequests[requestIndex]['hasResponded'] = true;
            }
          });
          
          // Refresh requests list from server to get updated counts
          _fetchActiveRequests();
        }
      } catch (e) {
        if (mounted) Navigator.of(context).pop();
        _showError('Failed to respond: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_activeRequests.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Colors.green.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No urgent blood requests at this time',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'When hospitals need your blood type, their requests will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _fetchActiveRequests,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  'Urgent Blood Requests',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red.shade700,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _fetchActiveRequests,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _activeRequests.length > 3 ? 3 : _activeRequests.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final request = _activeRequests[index];
                return _buildRequestItem(
                  context,
                  hospital: request['hospital']?['name'] ?? 'Hospital',
                  bloodType: request['bloodType'] ?? 'Unknown',
                  distance: request['distanceKm'] != null 
                      ? '${request['distanceKm']?.toStringAsFixed(1)} km' 
                      : 'Nearby',
                  requestId: request['id'],
                  urgent: index == 0,
                  createdAt: request['createdAt'],
                  status: request['status'],
                  donorResponses: request['donorResponses'] ?? [],
                  quantityNeeded: request['quantity'] ?? 1,
                  hasResponded: request['hasResponded'] ?? false,
                );
              },
            ),
            if (_activeRequests.length > 3) ...[
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/blood-requests');
                  },
                  child: Text(
                    'View all ${_activeRequests.length} requests',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRequestItem(
    BuildContext context, {
    required String hospital,
    required String bloodType,
    required String distance,
    required String requestId,
    String? createdAt,
    String? status,
    List<dynamic> donorResponses = const [],
    int quantityNeeded = 1,
    bool hasResponded = false,
    bool urgent = false,
  }) {
    String timeAgo = '';
    if (createdAt != null) {
      try {
        final requestTime = DateTime.parse(createdAt);
        final now = DateTime.now();
        final difference = now.difference(requestTime);
        
        if (difference.inMinutes < 60) {
          timeAgo = '${difference.inMinutes} min ago';
        } else if (difference.inHours < 24) {
          timeAgo = '${difference.inHours} hours ago';
        } else {
          timeAgo = '${difference.inDays} days ago';
        }
      } catch (e) {
        timeAgo = '';
      }
    }

    // Calculate response statistics
    int totalResponses = donorResponses.length;
    Map<String, int> bloodTypeCount = {};
    
    for (var response in donorResponses) {
      String responseBloodType = response['donor']?['bloodType'] ?? 'Unknown';
      bloodTypeCount[responseBloodType] = (bloodTypeCount[responseBloodType] ?? 0) + 1;
    }

    // Determine the status color and button state
    Color statusColor = Colors.red.shade100;
    String buttonText = 'Respond';
    bool isButtonEnabled = !hasResponded;
    Color buttonColor = Colors.red;

    if (status == 'PARTIALLY_FULFILLED') {
      statusColor = Colors.orange.shade100;
      if (hasResponded) {
        buttonText = 'Responded';
        isButtonEnabled = false;
        buttonColor = Colors.green;
      }
    } else if (status == 'FULFILLED') {
      statusColor = Colors.green.shade100;
      buttonText = 'Fulfilled';
      isButtonEnabled = false;
      buttonColor = Colors.green;
    } else if (hasResponded) {
      buttonText = 'Responded';
      isButtonEnabled = false;
      buttonColor = Colors.green;
    }

    if (urgent && status != 'FULFILLED' && status != 'PARTIALLY_FULFILLED') {
      statusColor = Colors.red.shade100;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(8),
        border: urgent 
            ? Border.all(color: Colors.red.shade300, width: 1) 
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Text(
                  bloodType,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            hospital,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (urgent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'URGENT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$distance away',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                        ),
                        if (timeAgo.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• $timeAgo',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: isButtonEnabled 
                    ? () => _respondToRequest(requestId)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                child: Text(buttonText),
              ),
            ],
          ),
          
          // Show response details if there are any responses
          if (totalResponses > 0) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        '$totalResponses/$quantityNeeded donors responded',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (bloodTypeCount.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: bloodTypeCount.entries.map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${entry.key}: ${entry.value}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}