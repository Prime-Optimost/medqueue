// Chat Message Model
// Represents a single message in patient-doctor conversations
// Used for displaying chat history and new messages

class ChatMessage {
  final String text;
  final bool isFromPatient;
  final DateTime timestamp;
  final String senderName;
  final String? messageId;

  ChatMessage({
    required this.text,
    required this.isFromPatient,
    required this.timestamp,
    required this.senderName,
    this.messageId,
  });

  // Factory constructor for creating from API response
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['content_preview'] ?? json['text'] ?? '',
      isFromPatient: json['direction'] == 'patient_to_doctor',
      timestamp: DateTime.parse(json['timestamp']),
      senderName: json['sender_name'] ?? (json['direction'] == 'patient_to_doctor' ? 'Patient' : 'Doctor'),
      messageId: json['whatsapp_message_id'],
    );
  }

  // Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'is_from_patient': isFromPatient,
      'timestamp': timestamp.toIso8601String(),
      'sender_name': senderName,
      'message_id': messageId,
    };
  }
}

// Patient Conversation Model (for doctor's inbox view)
class PatientConversation {
  final String patientId;
  final String patientName;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  PatientConversation({
    required this.patientId,
    required this.patientName,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory PatientConversation.fromJson(Map<String, dynamic> json) {
    return PatientConversation(
      patientId: json['patient_id'].toString(),
      patientName: json['patient_name'] ?? 'Unknown Patient',
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}

// Comments for academic documentation:
// - ChatMessage: Data model for individual chat messages
// - isFromPatient: Distinguishes patient vs doctor messages
// - senderName: Display name of the message sender
// - messageId: WhatsApp message ID for tracking
// - PatientConversation: Summary model for doctor's conversation list
// - unreadCount: Number of unread messages in conversation
// - JSON serialization: For API communication and local storage