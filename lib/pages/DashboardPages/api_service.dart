import 'dart:convert';
import 'dart:core';
import 'package:bloodbridge/pages/DashboardPages/BloodInventory.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://blood-bridge-2f7x.onrender.com';

  // Fetch inventory data from the backend
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

  // Update blood inventory in the backend
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

  // Create a new blood inventory item
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

  // Delete a blood inventory item
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
