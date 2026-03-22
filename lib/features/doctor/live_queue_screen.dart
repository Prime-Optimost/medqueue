import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/queue_service.dart';
import '../../features/auth/auth_provider.dart';

class LiveQueueScreen extends StatefulWidget {
  static const routeName = '/live-queue';
  final int doctorId;
  const LiveQueueScreen({super.key, required this.doctorId});

  @override
  State<LiveQueueScreen> createState() => _LiveQueueScreenState();
}

class _LiveQueueScreenState extends State<LiveQueueScreen> {
  final QueueService _queueService = QueueService();
  late Stream<QuerySnapshot> _queueStream;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().toIso8601String().split('T')[0];
    _queueStream = _queueService.getQueueStream(widget.doctorId, today);
  }

  Future<void> _callNext() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token != null) {
      await _queueService.callNext(token, widget.doctorId);
    }
  }

  Future<void> _completeConsultation(int queueId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token != null) {
      await _queueService.completeQueue(token, queueId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Queue')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _callNext,
              child: const Text('Call Next Patient'),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _queueStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No patients in queue'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final queueId = data['queueId'];
                    final patientName = data['patientName'] ?? 'Unknown';
                    final position = data['currentPosition'];
                    final status = data['status'];

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text('$patientName (Position $position)'),
                        subtitle: Text('Status: $status'),
                        trailing: status == 'in_consultation'
                            ? ElevatedButton(
                                onPressed: () => _completeConsultation(queueId),
                                child: const Text('Complete'),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
