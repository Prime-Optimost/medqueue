import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';

class PatientDashboard extends StatelessWidget {
  static const routeName = '/patient-dashboard';
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Book Appointment'),
                subtitle: const Text('Schedule a new appointment with a doctor'),
                onTap: () => Navigator.pushNamed(context, '/doctors-list'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.list),
                title: const Text('My Appointments'),
                subtitle: const Text('View and manage your appointments'),
                onTap: () => Navigator.pushNamed(context, '/my-appointments'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.chat),
                title: const Text('AI Health Assistant'),
                subtitle: const Text('Get instant health guidance and first-aid tips'),
                onTap: () => Navigator.pushNamed(context, '/chatbot'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.red.shade50,
              child: ListTile(
                leading: const Icon(Icons.emergency, color: Colors.red),
                title: const Text('Emergency SOS', style: TextStyle(color: Colors.red)),
                subtitle: const Text('One-tap emergency response with location'),
                onTap: () => Navigator.pushNamed(context, '/emergency'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.message, color: Colors.green),
                title: const Text('Chat with Doctor'),
                subtitle: const Text('Send messages to your assigned doctor'),
                onTap: () => Navigator.pushNamed(context, '/chat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
