import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/doctor_model.dart';
import '../../services/appointment_service.dart';
import '../../features/auth/auth_provider.dart';

class DoctorsListScreen extends StatefulWidget {
  static const routeName = '/doctors-list';
  const DoctorsListScreen({super.key});

  @override
  State<DoctorsListScreen> createState() => _DoctorsListScreenState();
}

class _DoctorsListScreenState extends State<DoctorsListScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  List<DoctorModel> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token != null) {
      final doctors = await _appointmentService.getDoctors(token);
      setState(() {
        _doctors = doctors;
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'busy':
        return Colors.orange;
      case 'on_leave':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Doctor')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _doctors.length,
              itemBuilder: (context, index) {
                final doctor = _doctors[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(doctor.fullName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Specialization: ${doctor.specialization}'),
                        Text('Fee: GHS ${doctor.consultationFee}'),
                        Row(
                          children: [
                            Text('Status: '),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _getStatusColor(doctor.availabilityStatus),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(doctor.availabilityStatus),
                          ],
                        ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: doctor.availabilityStatus == 'available'
                          ? () => Navigator.pushNamed(
                                context,
                                '/book-appointment',
                                arguments: doctor,
                              )
                          : null,
                      child: const Text('Book'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
