// Emergency Alerts Screen
// Admin view for monitoring and managing active emergency requests
// Features: List of active emergencies, status updates, dispatch management

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/emergency_service.dart';
import '../models/emergency_request.dart';

class EmergencyAlertsScreen extends StatefulWidget {
  const EmergencyAlertsScreen({super.key});

  @override
  State<EmergencyAlertsScreen> createState() => _EmergencyAlertsScreenState();
}

class _EmergencyAlertsScreenState extends State<EmergencyAlertsScreen> {
  final List<EmergencyRequest> _emergencies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveEmergencies();
  }

  Future<void> _loadActiveEmergencies() async {
    setState(() => _isLoading = true);

    try {
      final emergencies = await context.read<EmergencyService>().getActiveEmergencies();
      setState(() {
        _emergencies.clear();
        _emergencies.addAll(emergencies);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load emergencies: $e')),
      );
    }
  }

  Future<void> _updateEmergencyStatus(int emergencyId, String status) async {
    try {
      await context.read<EmergencyService>().updateEmergencyStatus(emergencyId, status);
      await _loadActiveEmergencies(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Emergency status updated to $status')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Alerts'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActiveEmergencies,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _emergencies.isEmpty
              ? const Center(
                  child: Text('No active emergencies'),
                )
              : RefreshIndicator(
                  onRefresh: _loadActiveEmergencies,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _emergencies.length,
                    itemBuilder: (context, index) {
                      final emergency = _emergencies[index];
                      return _EmergencyCard(
                        emergency: emergency,
                        onStatusUpdate: _updateEmergencyStatus,
                      );
                    },
                  ),
                ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  final EmergencyRequest emergency;
  final Function(int, String) onStatusUpdate;

  const _EmergencyCard({
    required this.emergency,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emergency, color: Colors.red, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency #${emergency.id}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        emergency.patientName,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(emergency.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    emergency.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '📍 Location: ${emergency.latitude.toStringAsFixed(6)}, ${emergency.longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 14),
            ),
            if (emergency.description != null && emergency.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '📝 ${emergency.description}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '🕒 Requested: ${_formatTimestamp(emergency.requestTime)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (emergency.responseTime != null) ...[
              const SizedBox(height: 4),
              Text(
                '🚑 Responded: ${_formatTimestamp(emergency.responseTime!)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (emergency.status == 'pending') ...[
                  ElevatedButton(
                    onPressed: () => onStatusUpdate(emergency.id, 'dispatched'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('Dispatch Ambulance'),
                  ),
                  const SizedBox(width: 8),
                ],
                if (emergency.status == 'dispatched') ...[
                  ElevatedButton(
                    onPressed: () => onStatusUpdate(emergency.id, 'completed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Mark Completed'),
                  ),
                  const SizedBox(width: 8),
                ],
                OutlinedButton(
                  onPressed: () => onStatusUpdate(emergency.id, 'cancelled'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.red;
      case 'dispatched':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

// Comments for academic documentation:
// - EmergencyAlertsScreen: Admin interface for emergency management
// - Active emergencies: Displays pending and dispatched requests
// - Status updates: Buttons to dispatch, complete, or cancel emergencies
// - Real-time updates: Refresh functionality and pull-to-refresh
// - Emergency cards: Detailed view of each emergency with location and description
// - Status indicators: Color-coded status badges
// - Timestamps: Request and response times for tracking
// - Action buttons: Context-sensitive based on current status