import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { donor, hospital }

class AuthService {
  final String _baseUrl = 'http://192.168.137.131:3005';
  
  // Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  // Get stored user ID
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }
  
  // Get user role
  Future<UserRole> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleString = prefs.getString('user_role') ?? 'donor';
    return roleString == 'donor' ? UserRole.donor : UserRole.hospital;
  }
  
  // Get user name
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
  
  // Login user with location
  Future<Map<String, dynamic>> login(String email, String password, {double? latitude, double? longitude}) async {
    try {
      // Include location data in login request
      final Map<String, dynamic> requestBody = {
        'email': email,
        'password': password,
      };
      
      // Add location if provided
      if (latitude != null) {
        requestBody['latitude'] = latitude;
      }
      
      if (longitude != null) {
        requestBody['longitude'] = longitude;
      }
       
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final authData = json.decode(response.body);
        
        // Save auth data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', authData['token']);
        await prefs.setString('user_id', authData['userId']);
        await prefs.setString('user_role', authData['role']);
        await prefs.setString('user_name', authData['name']);
        
        return authData;
      } else {
        final errorData = json.decode(response.body);
        final message = errorData['message'] ?? 'Authentication failed';
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }
  
  // Register new donor
  Future<Map<String, dynamic>> registerDonor(Map<String, dynamic> donorData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(donorData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        final message = errorData['message'] ?? 'Registration failed';
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }
  
Future<void> logout() async {
  try {
    final token = await getToken();
    if (token != null) {
      // Make API call to invalidate token on server
      await http.post(
        Uri.parse('$_baseUrl/auth/logout'),
        headers: {'Authorization': 'Bearer $token'},
      );
    }
  } catch (e) {
    // Continue with local logout even if server logout fails
    print('Server logout failed: $e');
  }
  
  // Clear local storage regardless
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('auth_token');
  await prefs.remove('user_id');
  await prefs.remove('user_role');
  await prefs.remove('user_name');
  await prefs.remove('location_updated_once');
}

  Future<void> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = json.decode(response.body);
        final message = errorData['message'] ?? 'Failed to send reset link';
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Failed to send reset link: ${e.toString()}');
    }
  }
  
  // Validate reset token - FIXED: simplified for direct validation
  Future<bool> validateResetToken(String token) async {
    try {
      // The token validation endpoint in the backend does redirection, not JSON response
      // This approach works better with the way the backend is designed
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/validate-reset-token?token=$token'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Invalid or expired token');
      }
    } catch (e) {
      throw Exception('Invalid or expired token');
    }
  }
  
  // Reset password with token - FIXED: simplified error handling
  Future<void> resetPassword(String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': token,
          'newPassword': newPassword,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        return;
      } else {
        // Try to parse error message
        try {
          final errorData = json.decode(response.body);
          final message = errorData['message'] ?? 'Password reset failed';
          throw Exception(message);
        } catch (_) {
          throw Exception('Password reset failed');
        }
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }
  
  
  // Make authenticated request
  Future<http.Response> authenticatedRequest(
    String endpoint, {
    required String method,
    Map<String, dynamic>? data,
  }) async {
    final token = await getToken();
    
    if (token == null) {
      throw Exception('Not authenticated');
    }
    
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    
    final uri = Uri.parse('$_baseUrl/$endpoint');
    
    switch (method.toUpperCase()) {
      case 'GET':
        return http.get(uri, headers: headers);
      case 'POST':
        return http.post(
          uri, 
          headers: headers,
          body: data != null ? json.encode(data) : null,
        );
      case 'PUT':
        return http.put(
          uri, 
          headers: headers,
          body: data != null ? json.encode(data) : null,
        );
      case 'PATCH':
        return http.patch(
          uri, 
          headers: headers,
          body: data != null ? json.encode(data) : null,
        );
      case 'DELETE':
        return http.delete(uri, headers: headers);
      default:
        throw Exception('Unsupported method: $method');
    }
  }
}