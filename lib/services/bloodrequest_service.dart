import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BloodRequestService {
  final String baseUrl = 'http://192.168.137.1:3004';
  final http.Client _httpClient = http.Client();

  // Get token from SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Create a blood request (authenticated)
  Future<List<dynamic>> requestDonorsByDistance({
    required String hospitalId,
    required double maxDistanceKm,
    required bool broadcastAll,
    String? requestedBloodType,  // Nullable for broadcasting
    double quantity = 1.0,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authorization token not found');

    try {
      final requestBody = jsonEncode({
        'hospitalId': hospitalId,
        'radius': maxDistanceKm,
        'quantity': quantity,
        'broadcastAll': broadcastAll,
        'bloodType': broadcastAll ? null : requestedBloodType,
      });

      final response = await _httpClient.post(
        Uri.parse('$baseUrl/blood-requests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to create blood request');
      }
    } catch (e) {
      throw Exception('Error creating blood request: ${e.toString()}');
    }
  }

  // Get all blood requests for a hospital
  Future<List<dynamic>> getHospitalRequests(String hospitalId) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/blood-requests/hospital/$hospitalId'),
      headers: {
        'Content-Type': 'application/json',
        // If auth is needed here, also include the token
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load blood requests');
    }
  }

  // Get the status of a specific request
  Future<Map<String, dynamic>> getRequestStatus(int requestId) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/blood-requests/$requestId'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load request status');
    }
  }

  // Cancel a blood request
  Future<void> cancelRequest(int requestId) async {
    final response = await _httpClient.delete(
      Uri.parse('$baseUrl/blood-requests/$requestId'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to cancel blood request');
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
