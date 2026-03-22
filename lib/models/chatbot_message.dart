// Chatbot Message Model
// Represents a single message in the chatbot conversation
// Used for displaying chat history and new messages

class ChatbotMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isEmergency;

  ChatbotMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isEmergency = false,
  });

  // Factory constructor for creating from API response
  factory ChatbotMessage.fromJson(Map<String, dynamic> json) {
    return ChatbotMessage(
      text: json['response'] ?? json['symptom_input'] ?? '',
      isUser: json['is_user'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      isEmergency: json['is_emergency_flagged'] ?? false,
    );
  }

  // Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'is_user': isUser,
      'timestamp': timestamp.toIso8601String(),
      'is_emergency': isEmergency,
    };
  }
}

// Comments for academic documentation:
// - ChatbotMessage: Data model for individual chat messages
// - isUser: Distinguishes between user input and bot responses
// - isEmergency: Flags messages that contain emergency symptoms
// - timestamp: When the message was sent/received
// - JSON serialization: For API communication and local storage