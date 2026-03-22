import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/firebase_options.dart';

// QueueService handles queue operations and Firebase integration.
// For academic purposes, every public call is commented to explain exactly what it does.
class QueueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final String _baseUrl = 'http://localhost:3000/api/queue';

  // Initialize Firebase
  Future<void> initializeFirebase() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // Request permission for notifications
    await _messaging.requestPermission();
    // Get FCM token (mock for now)
    String? token = await _messaging.getToken();
    debugPrint('FCM Token: $token');
  }

  // Join queue for an appointment
  Future<bool> joinQueue(String token, int appointmentId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/join'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'appointment_id': appointmentId}),
    );

    if (response.statusCode == 201) {
      return true;
    }
    debugPrint('Join queue failed: ${response.body}');
    return false;
  }

  // Get queue status
  Future<Map<String, dynamic>?> getQueueStatus(String token, int appointmentId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/status/$appointmentId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    debugPrint('Get queue status failed: ${response.body}');
    return null;
  }

  // Leave queue
  Future<bool> leaveQueue(String token, int queueId) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/leave/$queueId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  // Call next patient (doctor)
  Future<bool> callNext(String token, int doctorId) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/next/$doctorId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  // Mark consultation complete
  Future<bool> completeQueue(String token, int queueId) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/complete/$queueId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  // Get live queue for doctor
  Future<List<Map<String, dynamic>>> getLiveQueue(String token, int doctorId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/live/$doctorId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    }
    debugPrint('Get live queue failed: ${response.body}');
    return [];
  }

  // Send appointment reminder
  Future<bool> sendReminder(String token, int appointmentId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/notifications/reminder'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'appointment_id': appointmentId}),
    );

    return response.statusCode == 200;
  }

  // Stream queue updates from Firestore
  Stream<QuerySnapshot> getQueueStream(int doctorId, String date) {
    return _firestore
        .collection('queues')
        .doc(doctorId.toString())
        .collection('date')
        .doc(date)
        .collection('patients')
        .orderBy('currentPosition')
        .snapshots();
  }
}
