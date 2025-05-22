import 'dart:convert';
import 'package:bloodbridge/services/auth_service.dart';
import 'package:http/http.dart' as http;

class Hospital {
  final String id;
  final String name;
  final String email;
  
  Hospital({
    required this.id,
    required this.name,
    required this.email,
  });
  
  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }
}

class HospitalService {
  final AuthService _authService = AuthService();
  
  Future<Hospital> getCurrentHospital() async {
    final userId = await _authService.getUserId();
    if (userId == null) {
      throw Exception('User ID not found. Please login again.');
    }
    
    final response = await _authService.authenticatedRequest(
      'hospital/$userId',
      method: 'GET',
    );
    
    if (response.statusCode == 200) {
      return Hospital.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load hospital data');
    }
  }
}