import 'dart:async';
import 'dart:convert';
import 'package:bloodbridge/services/auth_service.dart';
import 'package:http/http.dart' as http;


class BloodRequestService {
  final AuthService _authService = AuthService();
  final String baseUrl = 'http://localhost:3005';

  Future<List<dynamic>> requestDonorsByDistance({
    required String bloodType,
    required double radius,
    required int quantity,
    bool broadcastAll = false,
  }) async {
    final token = await _authService.getToken();
    final userId = await _authService.getUserId();

    if (token == null || userId == null) {
      throw Exception('Authentication required');
    }

    // Create request body matching the controller's expected format
    final requestBody = {
      'hospitalId': userId,
      'bloodType': broadcastAll ? 'ALL' : bloodType,
      'radius': radius,
      'quantity': quantity,
      'broadcastAll': broadcastAll,
    };

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/blood-requests/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

  List<dynamic> _handleResponse(http.Response response) {
    final body = response.body;

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(body);
      return data is List ? data : [data];
    } else {
      final errorData = json.decode(body);
      final message = errorData['message'] ?? 'API Error: ${response.statusCode}';
      throw Exception(message);
    }
  }
  
  // Get all blood requests for a hospital
  Future<List<dynamic>> getHospitalRequests() async {
    final token = await _authService.getToken();
    final userId = await _authService.getUserId();
    
    if (token == null || userId == null) {
      throw Exception('Not authenticated');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/blood-requests/hospital/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        return responseData;
      } else {
        final errorData = json.decode(response.body);
        final message = errorData['message'] ?? 'Failed to fetch blood requests';
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Failed to load blood requests: ${e.toString()}');
    }
  }
  
  // Cancel a blood request
  Future<bool> cancelRequest(String requestId) async {
    final token = await _authService.getToken();
    
    if (token == null) {
      throw Exception('Not authenticated');
    }
    
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/blood-requests/$requestId/cancel'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = json.decode(response.body);
        final message = errorData['message'] ?? 'Failed to cancel blood request';
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Failed to cancel blood request: ${e.toString()}');
    }
  }
 
 // Get all blood requests for a donor
  Future<List<dynamic>> getDonorRequests() async {
    final token = await _authService.getToken();
    final userId = await _authService.getUserId();
    
    if (token == null || userId == null) {
      throw Exception('Not authenticated');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/blood-requests/donor/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        return responseData;
      } else {
        final errorData = json.decode(response.body);
        final message = errorData['message'] ?? 'Failed to fetch blood requests';
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Failed to load blood requests: ${e.toString()}');
    }
  }

Future<bool> respondToRequest(String requestId) async {
  final token = await _authService.getToken();
  final userId = await _authService.getUserId();
  
  if (token == null || userId == null) {
    throw Exception('Not authenticated');
  }
  
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/blood-requests/$requestId/respond'), // Remove the space
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'donorId': userId}), // Add the donorId in the request body
    );
    
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['success'] ?? true;
    } else {
      throw Exception('Failed to respond to request: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to respond to request: ${e.toString()}');
  }
}

    
  
  // Get blood request statistics for a hospital
  Future<Map<String, dynamic>> getRequestStatistics() async {
    final token = await _authService.getToken();
    final userId = await _authService.getUserId();
    
    if (token == null || userId == null) {
      throw Exception('Not authenticated');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/blood-requests/stats/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData;
      } else {
        final errorData = json.decode(response.body);
        final message = errorData['message'] ?? 'Failed to fetch statistics';
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Failed to load statistics: ${e.toString()}');
    }
  }
}