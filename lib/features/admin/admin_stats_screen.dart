// Admin Statistics Screen
// Visual analytics dashboard with charts for appointments, statuses, and queue metrics
// Uses fl_chart library for interactive and responsive data visualization

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants.dart';
import '../../core/widgets/error_snackbar.dart';
import '../../services/admin_service.dart';

class AdminStatsScreen extends StatefulWidget {
  static const routeName = AppConstants.adminStatsRoute;
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  AdminStats? _stats;
  List<AppointmentData> _appointmentData = [];
  List<StatusData> _statusData = [];
  List<QueueData> _queueData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load stats
      final stats = await context.read<AdminService>().getStats();

      // Load appointment data for charts (mock data for demo - replace with real API)
      final appointmentData = await context.read<AdminService>().getAppointmentChartData();
      final statusData = await context.read<AdminService>().getStatusChartData();
      final queueData = await context.read<AdminService>().getQueueChartData();

      setState(() {
        _stats = stats;
        _appointmentData = appointmentData;
        _statusData = statusData;
        _queueData = queueData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ErrorSnackbar.show(context, 'Failed to load statistics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics Dashboard'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    if (_stats != null) _buildSummaryCards(_stats!),

                    const SizedBox(height: 24),

                    // Appointments Chart
                    _buildChartSection(
                      'Appointments This Week',
                      _buildAppointmentsChart(),
                    ),

                    const SizedBox(height: 24),

                    // Status Distribution
                    _buildChartSection(
                      'Appointment Status Distribution',
                      _buildStatusChart(),
                    ),

                    const SizedBox(height: 24),

                    // Queue Performance
                    _buildChartSection(
                      'Average Queue Wait Times',
                      _buildQueueChart(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards(AdminStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Patients',
            stats.totalPatients.toString(),
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Active Queue',
            stats.activeQueueCount.toString(),
            Icons.queue,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(String title, Widget chart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
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
            child: SizedBox(
              height: 300,
              child: chart,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentsChart() {
    if (_appointmentData.isEmpty) {
      return const Center(child: Text('No appointment data available'));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _appointmentData.map((e) => e.count.toDouble()).reduce((a, b) => a > b ? a : b) + 5,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${_appointmentData[groupIndex].day}: ${rod.toY.round()}',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < _appointmentData.length) {
                  return Text(
                    _appointmentData[value.toInt()].day,
                    style: const TextStyle(fontSize: 12),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        barGroups: _appointmentData.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.count.toDouble(),
                color: Colors.blue,
                width: 20,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusChart() {
    if (_statusData.isEmpty) {
      return const Center(child: Text('No status data available'));
    }

    return PieChart(
      PieChartData(
        sections: _statusData.map((data) {
          return PieChartSectionData(
            value: data.percentage,
            title: '${data.status}\n${data.percentage.toStringAsFixed(1)}%',
            color: _getStatusColor(data.status),
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildQueueChart() {
    if (_queueData.isEmpty) {
      return const Center(child: Text('No queue data available'));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < _queueData.length) {
                  return Text(
                    _queueData[value.toInt()].doctor.substring(0, 3),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: _queueData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.avgWaitTime);
            }).toList(),
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            belowBarData: BarAreaData(show: false),
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'no_show':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

// Comments for academic documentation:
// - AdminStatsScreen: Visual analytics with multiple chart types
// - Bar chart for appointment trends over time
// - Pie chart for status distribution analysis
// - Line chart for queue performance metrics
// - Interactive tooltips and responsive design
// - Real-time data loading with error handling
// - Consistent card-based layout for all visualizations