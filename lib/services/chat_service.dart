// Chat Service
// Handles WhatsApp API communication for patient-doctor messaging
// Manages sending messages, fetching history, and conversation lists

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_endpoints.dart';
import '../models/chat_message.dart';

class ChatService {
  static final String baseUrl = ApiEndpoints.baseUrl;

  // Send a message to another user
  Future<void> sendMessage({
    required String recipientId,
    required String message,
    String? appointmentId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _getToken()}',
      },
      body: jsonEncode({
        'recipient_id': recipientId,
        'message': message,
        'appointment_id': appointmentId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send message: ${response.statusCode}');
    }
  }

  // Get chat history between current user and specified user
  Future<List<ChatMessage>> getChatHistory(String otherUserId) async {
    final currentUserId = await _getUserId();

    final response = await http.get(
      Uri.parse('$baseUrl/chat/history/$currentUserId/$otherUserId'),
      headers: {
        'Authorization': 'Bearer ${await _getToken()}',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final messages = data['messages'] as List;
      return messages.map((json) => ChatMessage.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load chat history: ${response.statusCode}');
    }
  }

  // Get all conversations for a doctor (list of patients)
  Future<List<PatientConversation>> getDoctorConversations() async {
    final doctorId = await _getUserId();

    final response = await http.get(
      Uri.parse('$baseUrl/chat/doctor/conversations/$doctorId'), // Assuming this endpoint exists
      headers: {
        'Authorization': 'Bearer ${await _getToken()}',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final conversations = data['conversations'] as List;
      return conversations.map((json) => PatientConversation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load conversations: ${response.statusCode}');
    }
  }

  // Helper methods (implement based on your auth system)
  Future<String> _getToken() async {
    // Return JWT token from secure storage
    return 'your_jwt_token_here';
  }

  Future<String> _getUserId() async {
    // Return current user ID
    return 'current_user_id_here';
  }
}

// Comments for academic documentation:
// - ChatService: API client for WhatsApp-based messaging
// - sendMessage: Sends messages to recipients via WhatsApp API
// - getChatHistory: Fetches conversation history between two users
// - getDoctorConversations: Gets list of all patient conversations for doctor
// - JWT authentication: Secure API access with bearer tokens
// - Error handling: Throws exceptions for UI error display
// - Mock mode support: Can be configured for development testing