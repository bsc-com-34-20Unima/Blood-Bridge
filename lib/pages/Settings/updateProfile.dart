import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileUpdateResult {
  final String name;
  final String email;
  final String? profileImageUrl;

  ProfileUpdateResult({
    required this.name,
    required this.email,
    this.profileImageUrl,
  });

  factory ProfileUpdateResult.fromJson(Map<String, dynamic> json) {
    return ProfileUpdateResult(
      name: json['name'],
      email: json['email'],
      profileImageUrl: json['profileImageUrl'],
    );
  }
}

Future<ProfileUpdateResult> updateProfile({
  required String name,
  required String email,
  String? imagePath, // Optional path to image file
}) async {
  final uri = Uri.parse('https://yourapi.com/api/profile/update');
  var request = http.MultipartRequest('POST', uri);
  request.fields['name'] = name;
  request.fields['email'] = email;

  if (imagePath != null) {
    request.files.add(await http.MultipartFile.fromPath('profileImage', imagePath));
  }

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return ProfileUpdateResult.fromJson(data);
  } else {
    throw Exception('Failed to update profile: ${response.body}');
  }
}
