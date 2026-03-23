import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/queue_service.dart';
import '../../features/auth/auth_provider.dart';

class AdminQueueMonitorScreen extends StatefulWidget {
  static const routeName = '/admin-queue-monitor';
  const AdminQueueMonitorScreen({super.key});

  @override
  State<AdminQueueMonitorScreen> createState() => _AdminQueueMonitorScreenState();
}

class _AdminQueueMonitorScreenState extends State<AdminQueueMonitorScreen> {
  final QueueService _queueService = QueueService();
  final List<Map<String, dynamic>> _doctors = [];
  // ignore: prefer_final_fields
  Map<int, List<Map<String, dynamic>>> _queues = {};
  // ignore: prefer_final_fields
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token != null) {
      // Mock: In production, get all doctors and their queues
      // For now, assume doctor IDs 1, 2, 3
      final doctorIds = [1, 2, 3];
      for (final id in doctorIds) {
        final queue = await _queueService.getLiveQueue(token, id);
        _queues[id] = queue;
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Queue Monitor')),
      body: ListView.builder(
        itemCount: _queues.length,
        itemBuilder: (context, index) {
          final doctorId = _queues.keys.elementAt(index);
          final queue = _queues[doctorId]!;
          final waitingCount = queue.where((p) => p['status'] == 'waiting').length;
          final inConsultationCount = queue.where((p) => p['status'] == 'in_consultation').length;

          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text('Doctor $doctorId'),
              subtitle: Text('Waiting: $waitingCount | In Consultation: $inConsultationCount'),
              trailing: IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/live-queue',
                  arguments: doctorId,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
