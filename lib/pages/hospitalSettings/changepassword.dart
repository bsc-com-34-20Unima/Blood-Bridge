import 'package:bloodbridge/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:bloodbridge/services/auth_service.dart';
import 'dart:convert';

class UpdateHospitalPage extends StatefulWidget {
  const UpdateHospitalPage({Key? key}) : super(key: key);

  @override
  _UpdateHospitalPageState createState() => _UpdateHospitalPageState();
}

class _UpdateHospitalPageState extends State<UpdateHospitalPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isFetching = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadHospitalDetails();
  }

  Future<void> _loadHospitalDetails() async {
    try {
      final hospitalId = await _authService.getUserId();
      if (hospitalId == null) throw Exception("User ID not found");

      final response = await _authService.authenticatedRequest(
        'hospital/$hospitalId',
        method: 'GET',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
        });
      } else {
        throw Exception('Failed to fetch hospital data');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching hospital info: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isFetching = false;
      });
    }
  }

  void _updateHospital() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final hospitalId = await _authService.getUserId();
      if (hospitalId == null) throw Exception("User ID not found");

      final Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
      };

      if (_passwordController.text.trim().isNotEmpty) {
        updateData['password'] = _passwordController.text.trim();
      }

      final response = await _authService.authenticatedRequest(
        'hospital/$hospitalId',
        method: 'PATCH',
        data: updateData,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hospital details updated successfully',
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green,
          ),
        );
        _passwordController.clear();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Update failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout Confirmation"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Logout"),
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _buildBoxDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hospital Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red[700],
        iconTheme: const IconThemeData(color: Colors.white),
         automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              _showLogoutConfirmationDialog(context);
            },
          ),
        ],
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: _buildBoxDecoration('Hospital Name'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter hospital name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: _buildBoxDecoration('Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value == null || !value.contains('@')
                              ? 'Enter a valid email'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _buildBoxDecoration('New Password').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateHospital,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Update Details',
                              style: TextStyle(
                                color: Colors.white,
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
