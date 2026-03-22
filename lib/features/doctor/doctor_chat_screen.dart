// Doctor Chat Screen
// Doctor's view for managing patient conversations
// Features: Patient list, individual chat interface, message history

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../models/chat_message.dart';
import 'chat_screen.dart'; // Reusing patient chat screen for individual chats

class DoctorChatScreen extends StatefulWidget {
  const DoctorChatScreen({super.key});

  @override
  State<DoctorChatScreen> createState() => _DoctorChatScreenState();
}

class _DoctorChatScreenState extends State<DoctorChatScreen> {
  final List<PatientConversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final conversations = await context.read<ChatService>().getDoctorConversations();
      setState(() {
        _conversations.clear();
        _conversations.addAll(conversations);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load conversations: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Messages'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? const Center(
                  child: Text('No patient conversations yet'),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      return _PatientConversationTile(
                        conversation: conversation,
                        onTap: () => _openChat(conversation),
                      );
                    },
                  ),
                ),
    );
  }

  void _openChat(PatientConversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          doctorId: conversation.patientId,
          doctorName: conversation.patientName,
        ),
      ),
    ).then((_) => _loadConversations()); // Refresh after returning from chat
  }
}

class _PatientConversationTile extends StatelessWidget {
  final PatientConversation conversation;

  const _PatientConversationTile({
    required this.conversation,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue,
        child: Text(
          conversation.patientName[0].toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        conversation.patientName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        conversation.lastMessage ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: conversation.unreadCount > 0
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : Text(
              _formatTimestamp(conversation.lastMessageTime),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
      onTap: onTap,
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}';
    } else if (difference.inHours > 0) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.minute}m ago';
    }
  }
}

// Comments for academic documentation:
// - DoctorChatScreen: Doctor's inbox view for all patient conversations
// - Conversation list: Shows all patients with recent message preview
// - Unread indicators: Red badges for unread message counts
// - Tap to chat: Opens individual chat screen for selected patient
// - Refresh: Pull-to-refresh to update conversation list
// - Patient avatars: Circle avatars with patient name initials
// - Timestamps: Shows when last message was received
// - Empty state: Message when no conversations exist