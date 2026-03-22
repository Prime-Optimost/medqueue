import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';

class DoctorDashboard extends StatelessWidget {
  static const routeName = '/doctor-dashboard';
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
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
                leading: const Icon(Icons.schedule),
                title: const Text('My Schedule'),
                subtitle: const Text('View and manage your appointments'),
                onTap: () => Navigator.pushNamed(context, '/doctor-schedule'),
              ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.message, color: Colors.green),
                title: const Text('Patient Messages'),
                subtitle: const Text('Chat with your patients via WhatsApp'),
                onTap: () => Navigator.pushNamed(context, '/doctor-chat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
