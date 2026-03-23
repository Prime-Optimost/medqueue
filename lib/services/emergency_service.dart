// Emergency Service
// Handles GPS location capture and SOS API communication
// Manages emergency request submission with location data

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/emergency_request.dart';

class EmergencyService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String baseUrl = 'http://localhost:3000/api'; // Update for production

  // Get stored JWT token
  Future<String?> _getToken() async {
    return await _secureStorage.read(key: 'jwt_token');
  }

  // Get current GPS location with high accuracy
  Future<Position> getCurrentLocation() async {
    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // Get current position with high accuracy
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }

  // Trigger emergency SOS with location data
  Future<SOSEmergencyResult> triggerSOS(double latitude, double longitude, {String? description}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/emergency/sos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _getToken()}', // Assuming JWT token
      },
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return SOSEmergencyResult(
        success: data['success'] ?? false,
        emergencyId: data['emergency_id']?.toString() ?? '',
        latitude: latitude,
        longitude: longitude,
      );
    } else {
      throw Exception('Failed to trigger SOS: ${response.statusCode}');
    }
  }

  // Get active emergencies for admin/doctor view
  Future<List<EmergencyRequest>> getActiveEmergencies() async {
    final response = await http.get(
      Uri.parse('$baseUrl/emergency/active'),
      headers: {
        'Authorization': 'Bearer ${await _getToken()}',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final emergencies = data['emergencies'] as List;
      return emergencies.map((json) => EmergencyRequest.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load emergencies: ${response.statusCode}');
    }
  }

  // Update emergency status (admin only)
  Future<void> updateEmergencyStatus(int emergencyId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/emergency/$emergencyId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _getToken()}',
      },
      body: jsonEncode({
        'status': status,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update status: ${response.statusCode}');
    }
  }
}

// Result model for SOS emergency trigger
class SOSEmergencyResult {
  final bool success;
  final String emergencyId;
  final double latitude;
  final double longitude;

  SOSEmergencyResult({
    required this.success,
    required this.emergencyId,
    required this.latitude,
    required this.longitude,
  });
}

// Comments for academic documentation:
// - EmergencyService: API client for emergency SOS functionality
// - getCurrentLocation: GPS capture with permission handling
// - triggerSOS: Sends emergency request with precise coordinates
// - High accuracy: Uses LocationAccuracy.high for emergency precision
// - Permission checks: Handles location permission requests
// - SOSEmergencyResult: Response wrapper with emergency details
// - Error handling: Throws exceptions for UI error management