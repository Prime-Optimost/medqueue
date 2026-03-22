import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';
import '../../features/auth/auth_provider.dart';

class DoctorScheduleScreen extends StatefulWidget {
  static const routeName = '/doctor-schedule';
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  List<AppointmentModel> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token != null) {
      final appointments = await _appointmentService.getDoctorSchedule(token);
      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.yellow;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'no_show':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  Future<void> _updateStatus(int id, String status) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token != null) {
      final success = await _appointmentService.updateStatus(token, id, status);
      if (success) {
        _loadSchedule();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $status')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Schedule')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
              ? const Center(child: Text('No upcoming appointments'))
              : ListView.builder(
                  itemCount: _appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = _appointments[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text('${appointment.patientName}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${appointment.appointmentDate} at ${appointment.appointmentTime}'),
                            Text('Reason: ${appointment.reason ?? 'N/A'}'),
                            Row(
                              children: [
                                Text('Status: '),
                                Chip(
                                  label: Text(appointment.status),
                                  backgroundColor: _getStatusColor(appointment.status),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: (appointment.status == 'pending' || appointment.status == 'confirmed')
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check),
                                    onPressed: () => _updateStatus(appointment.id, 'completed'),
                                    tooltip: 'Mark as Completed',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel),
                                    onPressed: () => _updateStatus(appointment.id, 'no_show'),
                                    tooltip: 'Mark as No Show',
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}
