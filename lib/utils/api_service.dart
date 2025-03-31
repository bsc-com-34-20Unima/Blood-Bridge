import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'constants.dart';

class ApiService {
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  final http.Client? client; // For testing with mock client

  ApiService({
    this.baseUrl = Constants.baseUrl,
    this.client,
    this.defaultHeaders = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  });

  String? _authToken;
  final _headers = <String, String>{};

  // Initialize with auth token if available
  void init({String? authToken}) {
    if (authToken != null) {
      setAuthToken(authToken);
    }
  }

  void setAuthToken(String token) {
    _authToken = token;
    _headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _authToken = null;
    _headers.remove('Authorization');
  }

  Map<String, String> get headers {
    return {...defaultHeaders, ..._headers};
  }

  Future<dynamic> testConnection() async {
    return _handleRequest(
      request: () => _client.get(
        Uri.parse('$baseUrl${Constants.testEndpoint}'),
        headers: headers,
      ),
      successMessage: '✅ Connection successful',
    );
  }

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParams?.map((k, v) => MapEntry(k, v.toString())),
    );

    return _handleRequest(
      request: () => _client.get(uri, headers: headers),
    );
  }

  Future<dynamic> post(String endpoint, dynamic body) async {
    return _handleRequest(
      request: () => _client.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
  }

  Future<dynamic> put(String endpoint, dynamic body) async {
    return _handleRequest(
      request: () => _client.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
  }

  Future<dynamic> delete(String endpoint) async {
    return _handleRequest(
      request: () => _client.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      ),
    );
  }

  http.Client get _client => client ?? http.Client();

  Future<dynamic> _handleRequest({
    required Future<http.Response> Function() request,
    String? successMessage,
  }) async {
    try {
      final response = await request().timeout(Constants.receiveTimeout);

      return _handleResponse(response, successMessage);
    } on SocketException {
      throw NetworkException(Constants.networkError);
    } on TimeoutException {
      throw NetworkException('Request timed out');
    } on http.ClientException {
      throw NetworkException(Constants.networkError);
    } catch (e) {
      throw AppException(Constants.unexpectedError);
    }
  }

  dynamic _handleResponse(http.Response response, [String? successMessage]) {
    final responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    switch (response.statusCode) {
      case 200:
      case 201:
        if (successMessage != null) {
          print('$successMessage: ${response.body}');
        }
        return responseBody;
      case 204:
        return null;
      case 400:
        throw BadRequestException(responseBody?['message'] ?? 'Invalid request');
      case 401:
        throw UnauthorizedException(responseBody?['message'] ?? 'Unauthorized');
      case 403:
        throw ForbiddenException(responseBody?['message'] ?? 'Forbidden');
      case 404:
        throw NotFoundException(responseBody?['message'] ?? 'Resource not found');
      case 422:
        throw ValidationException(responseBody?['errors'] ?? 'Validation failed');
      case 500:
      case 502:
      case 503:
        throw ServerException(responseBody?['message'] ?? Constants.serverError);
      default:
        throw AppException('Error: ${response.statusCode}');
    }
  }
}

// Exception classes
class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(super.message);
}

class BadRequestException extends AppException {
  BadRequestException(super.message);
}

class UnauthorizedException extends AppException {
  UnauthorizedException(super.message);
}

class ForbiddenException extends AppException {
  ForbiddenException(super.message);
}

class NotFoundException extends AppException {
  NotFoundException(super.message);
}

class ValidationException extends AppException {
  final dynamic errors;
  ValidationException(this.errors) : super('Validation failed');
}

class ServerException extends AppException {
  ServerException(super.message);
}