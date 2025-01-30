// lib/services/auth_service.dart
import 'dart:async';
import '../models/user.dart';

class AuthService {
  // Simulate user database
  final Map<String, Map<String, String>> _users = {
    'donor@bloodbridge.com': {
      'id': '1',
      'password': '123456',
      'role': 'donor'
    },
    'hospital@bloodbridge.com': {
      'id': '2',
      'password': '123456',
      'role': 'hospital'
    }
  };

  Future<User> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(Duration(seconds: 1));

    // Check if user exists
    final userData = _users[email.toLowerCase()];
    if (userData == null) {
      throw Exception('User not found');
    }

    // Verify password
    if (userData['password'] != password) {
      throw Exception('Invalid password');
    }

    // Create user object
    return User.fromJson({
      'id': userData['id']!,
      'email': email,
      'role': userData['role']!,
    });
  }

  Future<void> logout() async {
    // Implement logout logic here
    await Future.delayed(Duration(milliseconds: 500));
  }
}