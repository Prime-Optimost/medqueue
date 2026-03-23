// Admin Service
// API client for admin dashboard operations
// Handles all admin-related HTTP requests with error handling

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/appointment_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class PaginatedResult<T> {
  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaginatedResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

class AppointmentData {
  final String day;
  final int count;

  AppointmentData({required this.day, required this.count});

  factory AppointmentData.fromJson(Map<String, dynamic> json) {
    return AppointmentData(
      day: json['date'] as String,
      count: json['total_appointments'] as int,
    );
  }
}

class StatusData {
  final String status;
  final double percentage;

  StatusData({required this.status, required this.percentage});

  factory StatusData.fromJson(Map<String, dynamic> json, int totalAppointments) {
    final count = json['count'] as int;
    final percent = totalAppointments > 0 ? (count / totalAppointments * 100) : 0.0;
    return StatusData(status: json['status'] as String, percentage: percent);
  }
}

class QueueData {
  final String doctor;
  final double avgWaitTime;

  QueueData({required this.doctor, required this.avgWaitTime});

  factory QueueData.fromJson(Map<String, dynamic> json) {
    return QueueData(
      doctor: json['doctor_name'] as String,
      avgWaitTime: (json['avg_wait_minutes'] as num).toDouble(),
    );
  }
}

class AdminService {
  final AuthService _authService = AuthService();
  final String baseUrl = AppConstants.baseUrl;

  // Get admin statistics
  Future<AdminStats> getStats() async {
    final response = await _makeAuthenticatedRequest('GET', AppConstants.adminStatsEndpoint);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return AdminStats.fromJson(data);
    } else {
      throw Exception('Failed to load admin stats');
    }
  }

  // Get appointments with pagination and filters
  Future<PaginatedResult<AppointmentModel>> getAppointments({
    int page = 1,
    int limit = 20,
    String? status,
    int? doctorId,
    DateTime? date,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null) 'status': status,
      if (doctorId != null) 'doctor_id': doctorId.toString(),
      if (date != null) 'date': date.toIso8601String().split('T')[0],
    };

    final response = await _makeAuthenticatedRequest('GET', AppConstants.adminAppointmentsEndpoint, queryParams: queryParams);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final appts = (data['appointments'] as List)
          .map((appointment) => AppointmentModel.fromJson(Map<String, dynamic>.from(appointment)))
          .toList();

      return PaginatedResult<AppointmentModel>(
        items: appts,
        page: data['pagination']['page'] as int,
        limit: data['pagination']['limit'] as int,
        total: data['pagination']['total'] as int,
        totalPages: data['pagination']['pages'] as int,
      );
    } else {
      throw Exception('Failed to load appointments');
    }
  }

  // Update appointment status
  Future<void> updateAppointmentStatus(int appointmentId, String status) async {
    final response = await _makeAuthenticatedRequest(
      'PATCH',
      '/api/admin/appointments/$appointmentId/status',
      body: {'status': status},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update appointment status');
    }
  }

  // Get users with pagination and filters
  Future<PaginatedResult<UserModel>> getUsers({
    int page = 1,
    int limit = 20,
    String? role,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (role != null) 'role': role,
    };

    final response = await _makeAuthenticatedRequest('GET', AppConstants.adminUsersEndpoint, queryParams: queryParams);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final users = (data['users'] as List)
          .map((user) => UserModel.fromJson(Map<String, dynamic>.from(user)))
          .toList();

      return PaginatedResult<UserModel>(
        items: users,
        page: data['pagination']['page'] as int,
        limit: data['pagination']['limit'] as int,
        total: data['pagination']['total'] as int,
        totalPages: data['pagination']['pages'] as int,
      );
    } else {
      throw Exception('Failed to load users');
    }
  }

  // Update user status (active/inactive)
  Future<void> updateUserStatus(int userId, bool isActive) async {
    final response = await _makeAuthenticatedRequest(
      'PATCH',
      '/api/admin/users/$userId/status',
      body: {'is_active': isActive},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update user status');
    }
  }

  // Get no-show reports
  Future<List<NoshowReport>> getNoshowReports() async {
    final response = await _makeAuthenticatedRequest('GET', AppConstants.adminNoshowReportEndpoint);

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
    final response = await _makeAuthenticatedRequest('GET', AppConstants.adminQueueReportEndpoint);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['queueStats'] as List)
          .map((report) => QueueReport.fromJson(report))
          .toList();
    } else {
      throw Exception('Failed to load queue reports');
    }
  }

  // Get queue chart data for admin stats (wrapper over queue reports)
  Future<List<QueueData>> getQueueChartData() async {
    final queueReports = await getQueueReports();
    return queueReports
        .map((report) => QueueData(doctor: report.doctorName, avgWaitTime: report.avgWaitMinutes))
        .toList();
  }

  // Get appointment chart data for admin stats
  Future<List<AppointmentData>> getAppointmentChartData() async {
    final response = await _makeAuthenticatedRequest('GET', '/api/admin/reports/appointments-week');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['appointmentWeekStats'] as List)
          .map((item) => AppointmentData.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } else {
      throw Exception('Failed to load appointment chart data');
    }
  }

  // Get status distribution chart data for admin stats
  Future<List<StatusData>> getStatusChartData() async {
    final response = await _makeAuthenticatedRequest('GET', '/api/admin/reports/status-distribution');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final statusCounts = (data['statusDistribution'] as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      final total = statusCounts.fold<int>(0, (sum, item) => sum + (item['count'] as int));
      return statusCounts
          .map((item) => StatusData.fromJson(item, total))
          .toList();
    } else {
      throw Exception('Failed to load status chart data');
    }
  }

  // Get doctor slots
  Future<List<DoctorSlot>> getDoctorSlots() async {
    final response = await _makeAuthenticatedRequest('GET', AppConstants.adminCreateSlotsEndpoint);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['slots'] as List)
          .map((slot) => DoctorSlot.fromJson(slot))
          .toList();
    } else {
      throw Exception('Failed to load doctor slots');
    }
  }

  // Create new slot
  Future<void> createSlot(DoctorSlot slot) async {
    final response = await _makeAuthenticatedRequest(
      'POST',
      AppConstants.adminCreateSlotsEndpoint,
      body: slot.toJson(),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create slot');
    }
  }

  // Delete slot
  Future<void> deleteSlot(int slotId) async {
    final response = await _makeAuthenticatedRequest('DELETE', '/api/admin/doctors/slots/$slotId');

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
  final int todaysAppointments;
  final int activeQueueCount;
  final int pendingEmergencies;
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
    required this.todaysAppointments,
    required this.activeQueueCount,
    required this.pendingEmergencies,
    required this.averageWaitTime,
    required this.noshowRate,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['totalUsers'] ?? 0,
      totalDoctors: json['totalDoctors'] ?? 0,
      totalPatients: json['totalPatients'] ?? 0,
      totalAppointments: json['totalAppointments'] ?? 0,
      pendingAppointments: json['pendingAppointments'] ?? 0,
      completedAppointments: json['completedAppointments'] ?? 0,
      cancelledAppointments: json['cancelledAppointments'] ?? 0,
      todaysAppointments: json['todaysAppointments'] ?? 0,
      activeQueueCount: json['activeQueueCount'] ?? 0,
      pendingEmergencies: json['pendingEmergencies'] ?? 0,
      averageWaitTime: (json['averageWaitTime'] ?? 0).toDouble(),
      noshowRate: (json['noshowRate'] ?? 0).toDouble(),
    );
  }
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