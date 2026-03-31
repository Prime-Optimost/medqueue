import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/api_endpoints.dart';
import '../models/doctor_model.dart';
import '../models/appointment_model.dart';

// AppointmentService handles all appointment-related API calls.
// For academic purposes, every public call is commented to explain exactly what it does.
class AppointmentService {
  final String _baseUrl = '${ApiEndpoints.baseUrl}/appointments';

  // Get list of all doctors
  Future<List<DoctorModel>> getDoctors(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/doctors'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => DoctorModel.fromJson(json)).toList();
    }
    debugPrint('Get doctors failed: ${response.body}');
    return [];
  }

  // Get available slots for a doctor on a date
  Future<List<String>> getSlots(String token, int doctorId, String date) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/slots/$doctorId?date=$date'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((slot) => slot.toString()).toList();
    }
    debugPrint('Get slots failed: ${response.body}');
    return [];
  }

  // Book an appointment
  Future<bool> bookAppointment(String token, int doctorId, String date, String time, String reason) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/book'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'doctor_id': doctorId,
        'appointment_date': date,
        'appointment_time': time,
        'reason': reason,
      }),
    );

    if (response.statusCode == 201) {
      return true;
    }
    debugPrint('Book appointment failed: ${response.body}');
    return false;
  }

  // Get patient's appointments
  Future<List<AppointmentModel>> getMyAppointments(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/my'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => AppointmentModel.fromJson(json)).toList();
    }
    debugPrint('Get my appointments failed: ${response.body}');
    return [];
  }

  // Cancel appointment
  Future<bool> cancelAppointment(String token, int appointmentId) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/$appointmentId/cancel'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  // Reschedule appointment
  Future<bool> rescheduleAppointment(String token, int appointmentId, String newDate, String newTime) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/$appointmentId/reschedule'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'new_date': newDate,
        'new_time': newTime,
      }),
    );

    return response.statusCode == 200;
  }

  // Get doctor's schedule
  Future<List<AppointmentModel>> getDoctorSchedule(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/doctor/schedule'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => AppointmentModel.fromJson(json)).toList();
    }
    debugPrint('Get doctor schedule failed: ${response.body}');
    return [];
  }

  // Update appointment status
  Future<bool> updateStatus(String token, int appointmentId, String status) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/$appointmentId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );

    return response.statusCode == 200;
  }
}
