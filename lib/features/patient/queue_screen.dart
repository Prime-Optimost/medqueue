import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/queue_service.dart';
import '../../features/auth/auth_provider.dart';

class QueueScreen extends StatefulWidget {
  static const routeName = '/queue';
  final int appointmentId;
  const QueueScreen({super.key, required this.appointmentId});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  final QueueService _queueService = QueueService();
  Map<String, dynamic>? _queueStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQueueStatus();
  }

  Future<void> _loadQueueStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token != null) {
      final status = await _queueService.getQueueStatus(token, widget.appointmentId);
      setState(() {
        _queueStatus = status;
        _isLoading = false;
      });
    }
  }

  Future<void> _leaveQueue() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token != null && _queueStatus != null) {
      final success = await _queueService.leaveQueue(token, _queueStatus!['queueId']);
      if (success) {
        if (!mounted) return;
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_queueStatus == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Queue Status')),
        body: const Center(child: Text('Not in queue')),
      );
    }

    final position = _queueStatus!['position'];
    final waitTime = _queueStatus!['estimatedWaitTime'];
    final status = _queueStatus!['status'];

    String statusText;
    Color statusColor;
    if (status == 'waiting') {
      statusText = position == 1 ? 'You are next!' : 'Waiting';
      statusColor = position == 1 ? Colors.orange : Colors.blue;
    } else if (status == 'in_consultation') {
      statusText = 'In Consultation';
      statusColor = Colors.green;
    } else {
      statusText = status;
      statusColor = Colors.grey;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Queue Status')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              position.toString(),
              style: const TextStyle(fontSize: 100, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              statusText,
              style: TextStyle(fontSize: 24, color: statusColor),
            ),
            const SizedBox(height: 20),
            Text(
              'Estimated wait: $waitTime minutes',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _leaveQueue,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Leave Queue'),
            ),
          ],
        ),
      ),
    );
  }
}
