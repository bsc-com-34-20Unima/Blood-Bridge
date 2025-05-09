class Constants {
  // Base configuration
  static const String baseUrl = 'http://10.0.2.2:3004/api';
  
  // Endpoints
  static const String testEndpoint = '/test';
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 3);
  
  // Error messages
  static const String networkError = 'Network connection failed';
  static const String serverError = 'Server responded with error';
  static const String unexpectedError = 'Unexpected error occurred';
  
  // For different environments (optional)
  static String get developmentUrl => 'http://10.0.2.2:3004/api';
  static String get productionUrl => 'https://your-production-domain.com/api';
}