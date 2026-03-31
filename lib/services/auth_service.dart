import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../core/api_endpoints.dart';
import '../models/user_model.dart';

// AuthService handles communication with backend authentication API.
// For academic purposes, every public call is commented to explain exactly what it does.
class AuthService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _baseUrl = '${ApiEndpoints.baseUrl}/auth';

  // Register user endpoint call
  Future<int?> register(UserModel userModel, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': userModel.fullName,
        'phone_number': userModel.phoneNumber,
        'email': userModel.email,
        'password': password,
        'role': userModel.role,
      }),
    );

    if (response.statusCode == 201) {
      final body = jsonDecode(response.body);
      return body['user_id'];
    }
    debugPrint('Register failed: ${response.body}');
    return null;
  }

  // Verify OTP endpoint call
  Future<bool> verifyOTP(String userId, String otp) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'otp': otp}),
    );
    return response.statusCode == 200;
  }

  // Login endpoint call returns token and user details (or null on failure)
  Future<Map<String, dynamic>?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      await _secureStorage.write(key: 'jwt_token', value: body['token']);
      await _secureStorage.write(key: 'user_id', value: body['user']['id'].toString());
      return {
        'token': body['token'],
        'user': UserModel.fromJson(body['user']),
      };
    }

    debugPrint('Login failed: ${response.body}');
    return null;
  }

  // Logout endpoint call and clearing local secure storage
  Future<void> logout(String token) async {
    await http.post(
      Uri.parse('$_baseUrl/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    await _secureStorage.delete(key: 'jwt_token');
    await _secureStorage.delete(key: 'user_id');
  }

  // Check authentication status by validating stored token
  Future<bool> checkAuthStatus() async {
    final token = await getStoredToken();
    if (token == null) return false;

    try {
      // Validate token with backend
      final response = await http.get(
        Uri.parse('$_baseUrl/validate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Token validation failed: $e');
      return false;
    }
  }

  // Get stored JWT token
  Future<String?> getStoredToken() async {
    return await _secureStorage.read(key: 'jwt_token');
  }

  // Get stored user ID
  Future<String?> getStoredUserId() async {
    return await _secureStorage.read(key: 'user_id');
  }

  // Clear all stored authentication data
  Future<void> clearStoredData() async {
    await _secureStorage.delete(key: 'jwt_token');
    await _secureStorage.delete(key: 'user_id');
  }

  // Handle 401 responses by clearing stored data and redirecting to login
  Future<void> handleUnauthorized(BuildContext context) async {
    await clearStoredData();

    if (context.mounted) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );

      // Navigate to login screen
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

  // Helper method to make authenticated HTTP requests with automatic 401 handling
  Future<http.Response> authenticatedRequest(
    BuildContext context,
    String method,
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final token = await getStoredToken();
    if (token == null) {
      throw Exception('No authentication token available');
    }

    final authHeaders = {
      ...?headers,
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    http.Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(url, headers: authHeaders);
        break;
      case 'POST':
        response = await http.post(url, headers: authHeaders, body: body);
        break;
      case 'PUT':
        response = await http.put(url, headers: authHeaders, body: body);
        break;
      case 'PATCH':
        response = await http.patch(url, headers: authHeaders, body: body);
        break;
      case 'DELETE':
        response = await http.delete(url, headers: authHeaders);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    // Handle 401 Unauthorized responses
    if (response.statusCode == 401 && context.mounted) {
      await handleUnauthorized(context);
      throw Exception('Authentication failed');
    }

    return response;
  }
}
