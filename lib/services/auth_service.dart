import 'dart:io';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

enum UserRole { donor, hospital }

class AuthService {
  final String _baseUrl = 'http://192.168.28.248:3004';
  
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
        
        // Handle specific error for deleted accounts
        if (message.contains('deleted') || message.contains('not found')) {
          throw Exception('Account not found or has been deleted');
        }
        
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
  
  // Logout
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
  
  // Make authenticated request - FIXED PATCH ISSUE
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

    // Ensure the URL is correctly formatted
    String endpointPath = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final uri = Uri.parse('$_baseUrl/$endpointPath');
    
    developer.log('⚠️ Making ${method.toUpperCase()} request to: ${uri.toString()}');
    developer.log('⚠️ Headers: $headers');
    if (data != null) developer.log('⚠️ Body: ${json.encode(data)}');

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          return await http.get(uri, headers: headers);
        case 'POST':
          return await http.post(
            uri, 
            headers: headers,
            body: data != null ? json.encode(data) : null,
          );
        case 'PUT':
          return await http.put(
            uri, 
            headers: headers,
            body: data != null ? json.encode(data) : null,
          );
        case 'PATCH':
          final response = await http.patch(
            uri, 
            headers: headers,
            body: data != null ? json.encode(data) : null,
          );
          developer.log('⚠️ PATCH response status: ${response.statusCode}');
          developer.log('⚠️ PATCH response body: ${response.body}');
          return response;
        case 'DELETE':
          return await http.delete(
            uri, 
            headers: headers,
            body: data != null ? json.encode(data) : null,
          );
        default:
          throw Exception('Unsupported method: $method');
      }
    } catch (e) {
      developer.log('❌ HTTP request error: $e', error: e);
      rethrow;
    }
  }

  // Delete user account
  Future<void> deleteAccount({required String donorId, required String password}) async {
    try {
      final token = await getToken();
      
      if (token == null) {
        throw Exception('Not authenticated');
      }
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/donors/$donorId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'password': password,
        }),
      );
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to delete account');
      }
      
      // Clear all local storage on successful deletion
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw Exception('Delete account failed: ${e.toString()}');
    }
  }

  // Change user password
  Future<void> changePassword({
    required String donorId, 
    required String currentPassword, 
    required String newPassword,
  }) async {
    try {
      final token = await getToken();
      
      if (token == null) {
        throw Exception('Not authenticated');
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/donors/$donorId/change-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
      
      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to change password');
      }
      
      // Clear auth data to force re-login with new password
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      throw Exception('Password change failed: ${e.toString()}');
    }
  }

  // Update profile implementation
  Future<Map<String, dynamic>> updateProfile({
    required String donorId, 
    Map<String, dynamic> data = const {},
  }) async {
    try {
      final response = await authenticatedRequest(
        'donors/$donorId',
        method: 'PATCH',
        data: data,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception('Profile update failed: ${e.toString()}');
    }
  }


    // Send forgot password request
  Future<void> forgotPassword(String email) async {
    try {
      developer.log('Sending forgot password request for: $email');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      developer.log('Forgot password response: ${response.statusCode}');
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to send reset email');
      }
      
      // Success - no need to return anything
      developer.log('Reset password email sent successfully');
    } catch (e) {
      developer.log('Error sending reset password email: $e');
      throw Exception('Failed to send reset email: ${e.toString()}');
    }
  }

  // Reset password with token
  Future<void> resetPassword({required String token, required String newPassword}) async {
    try {
      developer.log('Resetting password with token');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': token,
          'newPassword': newPassword,
        }),
      );

      developer.log('Reset password response: ${response.statusCode}');
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to reset password');
      }
      
      // Success - no need to return anything
      developer.log('Password reset successful');
    } catch (e) {
      developer.log('Error resetting password: $e');
      throw Exception('Failed to reset password: ${e.toString()}');
    }
  }

  // Validate reset token
  Future<bool> validateResetToken(String token) async {
    try {
      developer.log('Validating reset token');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/validate-reset-token?token=$token'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      developer.log('Error validating reset token: $e');
      return false;
    }
  }
}
