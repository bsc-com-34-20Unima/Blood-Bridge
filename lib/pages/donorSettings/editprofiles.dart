import 'package:flutter/material.dart';
import 'package:bloodbridge/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

class EditProfilePage extends StatefulWidget {
  final String? donorId;  // Changed to nullable
  final String currentName;
  final String currentEmail;

  const EditProfilePage({
    Key? key,
    required this.donorId,
    required this.currentName,
    required this.currentEmail,
  }) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  
  // Base URL for API - same as in AuthService
  final String _baseUrl = 'https://blood-bridge-2f7x.onrender.com';
  
  bool _isLoading = false;
  bool _isLoadingUserId = false;
  bool _nameChanged = false;
  bool _emailChanged = false;
  String? _userId;  // Will store user ID from SharedPreferences if needed

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
    _emailController.text = widget.currentEmail;
    
    // Add listeners to detect changes
    _nameController.addListener(() {
      setState(() {
        _nameChanged = _nameController.text != widget.currentName;
      });
    });
    
    _emailController.addListener(() {
      setState(() {
        _emailChanged = _emailController.text != widget.currentEmail;
      });
    });
    
    // Debug the donor ID issue
    developer.log('⚠️ DONOR ID CHECK: ${widget.donorId}');
    if (widget.donorId == null || widget.donorId!.isEmpty) {
      developer.log('❌ Empty or null donor ID detected, will try to get from SharedPreferences');
      _getUserIdFromPrefs();
    } else {
      _userId = widget.donorId;
    }
    
    developer.log('Edit Profile initialized for donor ID: ${_userId ?? widget.donorId}');
    developer.log('Current name: ${widget.currentName}, Current email: ${widget.currentEmail}');
  }

  // Get user ID from SharedPreferences if not provided
  Future<void> _getUserIdFromPrefs() async {
    setState(() {
      _isLoadingUserId = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('user_id');
      developer.log('⚠️ Retrieved user_id from SharedPreferences: $storedUserId');
      
      setState(() {
        _userId = storedUserId;
        _isLoadingUserId = false;
      });
    } catch (e) {
      developer.log('❌ Error getting user ID from SharedPreferences: $e', error: e);
      setState(() {
        _isLoadingUserId = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Check if any field has been changed
  bool get _isFormChanged => _nameChanged || _emailChanged;

  // Get effective user ID - either from widget or from SharedPreferences
  String? get effectiveUserId => _userId ?? widget.donorId;

  // Direct API call for updating profile
  Future<Map<String, dynamic>> _directUpdateProfile(String donorId, Map<String, dynamic> data) async {
    try {
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated');
      }
      
      // Setup headers
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      
      // Construct URL - carefully ensuring no trailing slash before the ID
      final url = '$_baseUrl/donors/$donorId';
      
      developer.log('⚠️ DIRECT PATCH request to: $url');
      developer.log('⚠️ Headers: $headers');
      developer.log('⚠️ Body: ${json.encode(data)}');
      
      // Make the PATCH request
      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: json.encode(data),
      );
      
      developer.log('⚠️ PATCH response status: ${response.statusCode}');
      developer.log('⚠️ PATCH response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      developer.log('❌ Direct API call error: $e', error: e);
      rethrow;
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // If nothing changed, just return to previous screen
    if (!_isFormChanged) {
      Navigator.pop(context);
      return;
    }

    final userId = effectiveUserId;
    
    // Check if we have a valid user ID
    if (userId == null || userId.isEmpty) {
      developer.log('❌ No valid donor ID available for update');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No donor ID available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create the update object with only changed fields
      final Map<String, dynamic> updateData = {};
      
      if (_nameChanged) {
        updateData['name'] = _nameController.text.trim();
      }
      
      if (_emailChanged) {
        updateData['email'] = _emailController.text.trim();
      }
      
      developer.log('⚠️ Updating profile for donor ID: $userId');
      developer.log('⚠️ Update data: $updateData');
      
      // Only make the API call if we have changes
      if (updateData.isNotEmpty) {
        // Use direct API call instead of AuthService
        final result = await _directUpdateProfile(userId, updateData);
        
        developer.log('✅ Profile update result: $result');

        // Update shared preferences with new data
        final prefs = await SharedPreferences.getInstance();
        
        if (_nameChanged) {
          await prefs.setString('user_name', _nameController.text);
          developer.log('✅ Updated name in SharedPreferences');
        }
        
        if (_emailChanged) {
          await prefs.setString('user_email', _emailController.text);
          developer.log('✅ Updated email in SharedPreferences');
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          developer.log('✅ Profile update successful');
          Navigator.pop(context, true); // Return true to indicate successful update
        }
      } else {
        // No changes made
        developer.log('ℹ️ No changes to update');
        Navigator.pop(context);
      }
    } catch (e) {
      developer.log('❌ Update profile error: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading || _isLoadingUserId
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Profile initial display
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.red.shade100,
                        child: Text(
                          _nameController.text.isNotEmpty 
                              ? _nameController.text[0].toUpperCase() 
                              : '',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Donor ID display (for debugging)
                    Center(
                      child: Text(
                        "Donor ID: ${effectiveUserId ?? 'Not available'}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: "Full Name",
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person, color: Colors.red),
                        suffixIcon: _nameChanged 
                            ? Icon(Icons.check_circle, color: Colors.green) 
                            : null,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.email, color: Colors.red),
                        suffixIcon: _emailChanged 
                            ? Icon(Icons.check_circle, color: Colors.green) 
                            : null,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    // No user ID warning if applicable
                    if (effectiveUserId == null || effectiveUserId!.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Text(
                          "Warning: User ID not available. Profile updates may not work.",
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    
                    // Update Button - Only enabled if changes were made
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFormChanged && effectiveUserId != null && effectiveUserId!.isNotEmpty 
                            ? Colors.red 
                            : Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isFormChanged && effectiveUserId != null && effectiveUserId!.isNotEmpty
                          ? _updateProfile 
                          : null,
                      child: const Text(
                        "Update Profile",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    // Cancel Button
                    const SizedBox(height: 16),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}