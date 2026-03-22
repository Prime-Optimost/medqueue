// Admin Service
// API client for admin dashboard operations
// Handles all admin-related HTTP requests with error handling

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/appointment_model.dart';
import '../models/doctor_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class AdminService {
  final AuthService _authService = AuthService();
  final String baseUrl = AppConstants.apiBaseUrl;

  // Get admin statistics
  Future<AdminStats> getStats() async {
    final response = await _makeAuthenticatedRequest('GET', '/admin/stats');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return AdminStats.fromJson(data);
    } else {
      throw Exception('Failed to load admin stats');
    }
  }

  // Get appointments with pagination and filters
  Future<AppointmentsResult> getAppointments({
    int page = 1,
    int limit = 20,
    String? status,
    String? doctorId,
    String? date,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null) 'status': status,
      if (doctorId != null) 'doctorId': doctorId,
      if (date != null) 'date': date,
    };

    final uri = Uri.parse('$baseUrl/admin/appointments').replace(queryParameters: queryParams);

    final response = await _makeAuthenticatedRequest('GET', '/admin/appointments', queryParams: queryParams);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final appointments = (data['appointments'] as List)
          .map((appointment) => AppointmentModel.fromJson(appointment))
          .toList();
      final pagination = data['pagination'] as Map<String, dynamic>;
      return AppointmentsResult(
        appointments: appointments,
        totalPages: pagination['pages'] ?? 1,
      );
    } else {
      throw Exception('Failed to load appointments');
    }
  }

  // Update appointment status
  Future<void> updateAppointmentStatus(int appointmentId, String status) async {
    final response = await _makeAuthenticatedRequest(
      'PATCH',
      '/admin/appointments/$appointmentId/status',
      body: {'status': status},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update appointment status');
    }
  }

  // Get users with pagination and filters
  Future<List<User>> getUsers({
    int page = 1,
    int limit = 20,
    String? role,
    String? status,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (role != null) 'role': role,
      if (status != null) 'status': status,
    };

    final response = await _makeAuthenticatedRequest('GET', '/admin/users', queryParams: queryParams);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['users'] as List)
          .map((user) => User.fromJson(user))
          .toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  // Update user status
  Future<void> updateUserStatus(int userId, String status) async {
    final response = await _makeAuthenticatedRequest(
      'PATCH',
      '/admin/users/$userId/status',
      body: {'status': status},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update user status');
    }
  }

  // Get no-show reports
  Future<List<NoshowReport>> getNoshowReports() async {
    final response = await _makeAuthenticatedRequest('GET', '/admin/reports/noshow');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['reports'] as List)
          .map((report) => NoshowReport.fromJson(report))
          .toList();
    } else {
      throw Exception('Failed to load no-show reports');
    }
  }

  // Get queue performance reports
  Future<List<QueueReport>> getQueueReports() async {
    final response = await _makeAuthenticatedRequest('GET', '/admin/reports/queue');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['reports'] as List)
          .map((report) => QueueReport.fromJson(report))
          .toList();
    } else {
      throw Exception('Failed to load queue reports');
    }
  }

  // Get doctor slots
  Future<List<DoctorSlot>> getDoctorSlots() async {
    final response = await _makeAuthenticatedRequest('GET', '/admin/slots');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['slots'] as List)
          .map((slot) => DoctorSlot.fromJson(slot))
          .toList();
    } else {
      throw Exception('Failed to load doctor slots');
    }
  }

  // Create new slots for a doctor
  Future<void> createDoctorSlots({
    required int doctorId,
    required String date,
    required String startTime,
    required String endTime,
    required int intervalMinutes,
  }) async {
    final response = await _makeAuthenticatedRequest(
      'POST',
      '/admin/doctors/slots',
      body: {
        'doctor_id': doctorId,
        'date': date,
        'start_time': startTime,
        'end_time': endTime,
        'interval_minutes': intervalMinutes,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create doctor slots');
    }
  }

  // Delete slot
  Future<void> deleteSlot(int slotId) async {
    final response = await _makeAuthenticatedRequest('DELETE', '/admin/slots/$slotId');

    if (response.statusCode != 200) {
      throw Exception('Failed to delete slot');
    }
  }

  // Helper method to make authenticated requests
  Future<http.Response> _makeAuthenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    final token = await _authService.getStoredToken();
    if (token == null) {
      throw Exception('No authentication token available');
    }

    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final encodedBody = body != null ? json.encode(body) : null;

    http.Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(uri, headers: headers, body: encodedBody);
        break;
      case 'PUT':
        response = await http.put(uri, headers: headers, body: encodedBody);
        break;
      case 'PATCH':
        response = await http.patch(uri, headers: headers, body: encodedBody);
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    return response;
  }
}

// Data models for admin operations
class AdminStats {
  final int totalUsers;
  final int totalDoctors;
  final int totalPatients;
  final int totalAppointments;
  final int pendingAppointments;
  final int completedAppointments;
  final int cancelledAppointments;
  final double averageWaitTime;
  final double noshowRate;

  AdminStats({
    required this.totalUsers,
    required this.totalDoctors,
    required this.totalPatients,
    required this.totalAppointments,
    required this.pendingAppointments,
    required this.completedAppointments,
    required this.cancelledAppointments,
    required this.averageWaitTime,
    required this.noshowRate,
  });

  int get todaysAppointments => pendingAppointments;
  int get activeQueueCount => pendingAppointments;

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['totalUsers'] ?? 0,
      totalDoctors: json['totalDoctors'] ?? 0,
      totalPatients: json['totalPatients'] ?? 0,
      totalAppointments: json['totalAppointments'] ?? 0,
      pendingAppointments: json['pendingAppointments'] ?? 0,
      completedAppointments: json['completedAppointments'] ?? 0,
      cancelledAppointments: json['cancelledAppointments'] ?? 0,
      averageWaitTime: (json['averageWaitTime'] ?? 0).toDouble(),
      noshowRate: (json['noshowRate'] ?? 0).toDouble(),
    );
  }
}

class AppointmentsResult {
  final List<AppointmentModel> appointments;
  final int totalPages;

  AppointmentsResult({
    required this.appointments,
    required this.totalPages,
  });
}

class NoshowReport {
  final int week;
  final int totalAppointments;
  final int noshows;
  final double noshowRate;

  NoshowReport({
    required this.week,
    required this.totalAppointments,
    required this.noshows,
    required this.noshowRate,
  });

  factory NoshowReport.fromJson(Map<String, dynamic> json) {
    return NoshowReport(
      week: json['week'] ?? 0,
      totalAppointments: json['totalAppointments'] ?? 0,
      noshows: json['noshows'] ?? 0,
      noshowRate: (json['noshowRate'] ?? 0).toDouble(),
    );
  }
}

class QueueReport {
  final String doctorName;
  final DateTime date;
  final double avgWaitMinutes;

  QueueReport({
    required this.doctorName,
    required this.date,
    required this.avgWaitMinutes,
  });

  factory QueueReport.fromJson(Map<String, dynamic> json) {
    return QueueReport(
      doctorName: json['doctorName'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      avgWaitMinutes: (json['avgWaitMinutes'] ?? 0).toDouble(),
    );
  }
}

class DoctorSlot {
  final int id;
  final int doctorId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int maxPatients;
  final int availableSlots;

  DoctorSlot({
    required this.id,
    required this.doctorId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.maxPatients,
    required this.availableSlots,
  });

  factory DoctorSlot.fromJson(Map<String, dynamic> json) {
    return DoctorSlot(
      id: json['id'] ?? 0,
      doctorId: json['doctorId'] ?? 0,
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      maxPatients: json['maxPatients'] ?? 0,
      availableSlots: json['availableSlots'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'date': date.toIso8601String().split('T')[0],
      'startTime': startTime,
      'endTime': endTime,
      'maxPatients': maxPatients,
    };
  }
}

// Comments for academic documentation:
// - AdminService: Complete API client for admin operations
// - Methods for statistics, appointments, users, reports, and slots
// - Proper error handling and JSON serialization
// - Data models for all admin response types
// - JWT authentication placeholder for security
// - Pagination support for large datasets
// - CRUD operations for slot management