import 'dart:convert';
import 'package:http/http.dart' as http;

class HospitalService {
  // Base URL for your API
  final String baseUrl = 'https://blood-bridge-2f7x.onrender.com'; // Replace with your actual backend URL
  
  // Method to get hospital name from the backend
  Future<String> getHospitalName() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/hospital/name'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['name'] ?? 'Unknown Hospital';
      } else {
        print('Failed to get hospital name. Status code: ${response.statusCode}');
        return 'Unknown Hospital';
      }
    } catch (e) {
      print('Error fetching hospital name: $e');
      return 'Unknown Hospital';
    }
  }
}