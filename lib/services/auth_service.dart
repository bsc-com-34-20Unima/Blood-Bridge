import 'package:bloodbridge/models/donor.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { donor, hospital }

class AuthService {
  final String _baseUrl = 'http://192.168.137.86:3004';

  // Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Register Donor (fully implemented)
  Future<void> registerDonor(Map<String, Object> donorData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(donorData),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode != 201) {
        throw Exception(responseData['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration error: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // Login
  Future<Map<String, dynamic>> login(
    String email,
    String password, {
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', responseData['token']);
        await prefs.setString('user_id', responseData['userId']);
        await prefs.setString('user_role', responseData['role']);
        await prefs.setString('user_name', responseData['name']);
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login error: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final token = await getToken();
      if (token != null) {
        await http.post(
          Uri.parse('$_baseUrl/auth/logout'),
          headers: {'Authorization': 'Bearer $token'},
        );
      }
    } finally {
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('user_role');
      await prefs.remove('user_name');
      await prefs.remove('location_updated_once');
    }
  }

  // Change Password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.patch(
        Uri.parse('$_baseUrl/donor/password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Password change failed');
      }
    } catch (e) {
      throw Exception('Password change error: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // Update Profile
  Future<Donor> updateProfile(Donor updatedUser) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.patch(
        Uri.parse('$_baseUrl/donor/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updatedUser.toJson()),
      );

      if (response.statusCode == 200) {
        return Donor.fromJson(json.decode(response.body));
      } else {
        throw Exception(json.decode(response.body)['message'] ?? 'Update failed');
      }
    } catch (e) {
      throw Exception('Profile update error: ${e.toString()}');
    }
  }

  // Delete Account
  Future<bool> deleteAccount() async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('$_baseUrl/donor/account'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        await logout();
        return true;
      } else {
        throw Exception(json.decode(response.body)['message'] ?? 'Deletion failed');
      }
    } catch (e) {
      throw Exception('Account deletion error: ${e.toString()}');
    }
  }

  // Get Current User
  Future<Donor?> getCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl/donor/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return Donor.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Helper methods
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<UserRole> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleString = prefs.getString('user_role') ?? 'donor';
    return roleString == 'donor' ? UserRole.donor : UserRole.hospital;
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
