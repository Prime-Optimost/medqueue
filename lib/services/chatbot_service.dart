// Chatbot Service
// Handles API communication for AI chatbot functionality
// Manages sending messages and fetching chat history

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_endpoints.dart';
import '../models/chatbot_message.dart';

class ChatbotService {
  static final String baseUrl = ApiEndpoints.baseUrl;

  // Send a message to the chatbot and get response
  Future<ChatbotResponse> sendMessage(String message, String sessionId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chatbot/message'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _getToken()}', // Assuming JWT token
      },
      body: jsonEncode({
        'symptom_input': message,
        'session_id': sessionId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ChatbotResponse(
        response: data['response'],
        isEmergencyFlagged: data['is_emergency_flagged'],
      );
    } else {
      throw Exception('Failed to send message: ${response.statusCode}');
    }
  }

  // Get chat history for the current user
  Future<List<ChatbotMessage>> getChatHistory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/chatbot/history/${await _getUserId()}'),
      headers: {
        'Authorization': 'Bearer ${await _getToken()}',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final interactions = data['interactions'] as List;
      return interactions.map((json) => ChatbotMessage.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load chat history: ${response.statusCode}');
    }
  }

  // Helper methods (implement based on your auth system)
  Future<String> _getToken() async {
    // Return JWT token from secure storage
    // Implementation depends on your authentication system
    return 'your_jwt_token_here';
  }

  Future<String> _getUserId() async {
    // Return current user ID
    // Implementation depends on your authentication system
    return 'current_user_id_here';
  }
}

// Response model for chatbot API
class ChatbotResponse {
  final String response;
  final bool isEmergencyFlagged;

  ChatbotResponse({
    required this.response,
    required this.isEmergencyFlagged,
  });
}

// Comments for academic documentation:
// - ChatbotService: API client for chatbot interactions
// - sendMessage: Sends user symptoms to AI and returns response
// - getChatHistory: Fetches previous conversations for continuity
// - JWT authentication: Secure API access with bearer tokens
// - Error handling: Throws exceptions for UI error display
// - ChatbotResponse: Wrapper for API response data