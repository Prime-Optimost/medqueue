// Admin Reports Screen
// Comprehensive reporting dashboard for system analytics and evaluation metrics
// Displays no-show rates and queue performance data for project documentation

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/widgets/error_snackbar.dart';
import '../../services/admin_service.dart';

class AdminReportsScreen extends StatefulWidget {
  static const routeName = AppConstants.adminReportsRoute;
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  List<NoshowReport> _noshowReports = [];
  List<QueueReport> _queueReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    try {
      final noshowReports = await context.read<AdminService>().getNoshowReports();
      final queueReports = await context.read<AdminService>().getQueueReports();

      setState(() {
        _noshowReports = noshowReports;
        _queueReports = queueReports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ErrorSnackbar.show(context, 'Failed to load reports: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReports,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // No-Show Rate Report
                    _buildReportSection(
                      'No-Show Rate Analysis',
                      'Weekly no-show statistics for the past 12 weeks',
                      _buildNoshowReport(),
                    ),

                    const SizedBox(height: 24),

                    // Queue Performance Report
                    _buildReportSection(
                      'Queue Performance Metrics',
                      'Average wait times per doctor over the past 30 days',
                      _buildQueueReport(),
                    ),

                    const SizedBox(height: 24),

                    // Summary Statistics
                    _buildSummaryStats(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReportSection(String title, String subtitle, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ),
      ],
    );
  }

  Widget _buildNoshowReport() {
    if (_noshowReports.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No no-show data available'),
        ),
      );
    }

    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Week',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Total Appointments',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'No-Shows',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'No-Show Rate',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),

        // Table Rows
        ..._noshowReports.map((report) => Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Week ${report.week}'),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  report.totalAppointments.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  report.noshows.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${report.noshowRate.toStringAsFixed(2)}%',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: report.noshowRate > 15 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildQueueReport() {
    if (_queueReports.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No queue performance data available'),
        ),
      );
    }

    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Doctor',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Date',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Avg Wait Time',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),

        // Table Rows
        ..._queueReports.map((report) => Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(report.doctorName),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  report.date.toLocal().toString().split(' ')[0],
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${report.avgWaitMinutes.toStringAsFixed(1)} min',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: report.avgWaitMinutes > 30 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildSummaryStats() {
    final totalAppointments = _noshowReports.fold<int>(0, (sum, report) => sum + report.totalAppointments);
    final totalNoshows = _noshowReports.fold<int>(0, (sum, report) => sum + report.noshows);
    final avgNoshowRate = totalAppointments > 0 ? (totalNoshows / totalAppointments * 100) : 0;

    final avgWaitTime = _queueReports.isNotEmpty
        ? _queueReports.map((r) => r.avgWaitMinutes).reduce((a, b) => a + b) / _queueReports.length
        : 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary Statistics (Last 12 Weeks)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Appointments',
                    totalAppointments.toString(),
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    'Average No-Show Rate',
                    '${avgNoshowRate.toStringAsFixed(2)}%',
                    Icons.warning,
                    avgNoshowRate > 15 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Average Wait Time',
                    '${avgWaitTime.toStringAsFixed(1)} min',
                    Icons.access_time,
                    avgWaitTime > 30 ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    'Total No-Shows',
                    totalNoshows.toString(),
                    Icons.cancel,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Comments for academic documentation:
// - AdminReportsScreen: Comprehensive reporting for project evaluation
// - No-show rate analysis with weekly breakdowns
// - Queue performance metrics with doctor-specific data
// - Table-based layouts suitable for documentation
// - Color-coded indicators for performance thresholds
// - Summary statistics for executive overview
// - Data structured for direct inclusion in test reports