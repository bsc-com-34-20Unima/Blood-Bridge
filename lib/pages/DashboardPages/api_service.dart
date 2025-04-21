import 'dart:convert';
import 'package:bloodbridge/pages/DashboardPages/BloodInventory.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.137.86:3004';

  // LOGIN METHOD
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/login');

      final body = {
        'email': email,
        'password': password,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  // FETCH BLOOD INVENTORY
  Future<List<BloodInventory>> fetchInventory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/blood-inventory'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => BloodInventory.fromJson(item)).toList();
      } else {
        throw Exception(
            'Failed to load blood inventory. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // UPDATE BLOOD INVENTORY
  Future<BloodInventory> updateInventory(int id, int availableUnits) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/blood-inventory/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'availableUnits': availableUnits}),
      );

      if (response.statusCode == 200) {
        return BloodInventory.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
            'Failed to update inventory. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // CREATE BLOOD INVENTORY
  Future<BloodInventory> createInventory({
    required String bloodGroup,
    required int availableUnits,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/blood-inventory'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'bloodGroup': bloodGroup,
          'availableUnits': availableUnits,
        }),
      );

      if (response.statusCode == 201) {
        return BloodInventory.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
            'Failed to create inventory. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // DELETE BLOOD INVENTORY
  Future<void> deleteInventory(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/blood-inventory/$id'),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to delete inventory. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
