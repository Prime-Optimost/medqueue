import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/widgets/error_snackbar.dart';
import '../auth/auth_provider.dart';
import '../../services/admin_service.dart';

class AdminDashboard extends StatefulWidget {
  static const routeName = AppConstants.adminDashboardRoute;
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  AdminStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      final stats = await context.read<AdminService>().getStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ErrorSnackbar.show(context, 'Failed to load dashboard stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_stats != null)
                _buildStatsGrid(_stats!)
              else
                const Center(child: Text('Failed to load statistics')),

              const SizedBox(height: 24),

              // Management Cards
              const Text(
                'Management',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildManagementGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(AdminStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Total Patients',
          stats.totalPatients.toString(),
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          'Total Doctors',
          stats.totalDoctors.toString(),
          Icons.medical_services,
          Colors.green,
        ),
        _buildStatCard(
          'Today\'s Appointments',
          stats.todaysAppointments.toString(),
          Icons.calendar_today,
          Colors.orange,
        ),
        _buildStatCard(
          'Active Queue',
          stats.activeQueueCount.toString(),
          Icons.queue,
          Colors.purple,
        ),
        _buildStatCard(
          'Pending Emergencies',
          stats.pendingEmergencies.toString(),
          Icons.emergency,
          Colors.red,
          isEmergency: true,
        ),
        _buildStatCard(
          'No-Show Rate',
          '${stats.noshowRate}%',
          Icons.warning,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool isEmergency = false}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isEmergency ? Colors.red : color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isEmergency ? Colors.red : color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildManagementCard(
          'Statistics',
          'View detailed analytics',
          Icons.bar_chart,
          Colors.blue,
          AppConstants.adminStatsRoute,
        ),
        _buildManagementCard(
          'Appointments',
          'Manage all appointments',
          Icons.calendar_month,
          Colors.green,
          AppConstants.adminAppointmentsRoute,
        ),
        _buildManagementCard(
          'Users',
          'Manage user accounts',
          Icons.people_alt,
          Colors.orange,
          AppConstants.adminUsersRoute,
        ),
        _buildManagementCard(
          'Reports',
          'View system reports',
          Icons.analytics,
          Colors.purple,
          AppConstants.adminReportsRoute,
        ),
        _buildManagementCard(
          'Emergency Alerts',
          'Monitor emergencies',
          Icons.emergency,
          Colors.red,
          AppConstants.emergencyAlertsRoute,
        ),
        _buildManagementCard(
          'Manage Slots',
          'Create doctor slots',
          Icons.schedule,
          Colors.teal,
          AppConstants.manageSlotsRoute,
        ),
      ],
    );
  }

  Widget _buildManagementCard(String title, String subtitle, IconData icon, Color color, String route) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Comments for academic documentation:
// - AdminDashboard: Comprehensive admin control center
// - Real-time statistics display with visual cards
// - Management grid for navigation to all admin features
// - Pull-to-refresh for live data updates
// - Error handling with consistent snackbar notifications
// - Color-coded cards for different metrics and functions
