import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/otp_screen.dart';
import 'features/admin/admin_dashboard_screen.dart';
import 'features/admin/admin_stats_screen.dart';
import 'features/admin/admin_appointments_screen.dart';
import 'features/admin/admin_users_screen.dart';
import 'features/admin/admin_reports_screen.dart';
import 'features/admin/admin_manage_slots_screen.dart';
import 'features/doctor/doctor_dashboard_screen.dart';
import 'features/patient/patient_dashboard_screen.dart';
import 'features/patient/doctors_list_screen.dart';
import 'features/patient/book_appointment_screen.dart';
import 'features/patient/my_appointments_screen.dart';
import 'features/patient/queue_screen.dart';
import 'features/doctor/doctor_schedule_screen.dart';
import 'features/doctor/live_queue_screen.dart';
import 'features/admin/admin_queue_monitor_screen.dart';
import 'services/admin_service.dart';

void main() {
  runApp(const MedQueueApp());
}

class MedQueueApp extends StatelessWidget {
  const MedQueueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        Provider(create: (_) => AdminService()),
      ],
      child: MaterialApp(
        title: 'MedQueue GH',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
        routes: {
          LoginScreen.routeName: (_) => const LoginScreen(),
          RegisterScreen.routeName: (_) => const RegisterScreen(),
          OTPScreen.routeName: (_) => const OTPScreen(),
          PatientDashboard.routeName: (_) => const PatientDashboard(),
          DoctorDashboard.routeName: (_) => const DoctorDashboard(),
          AdminDashboard.routeName: (_) => const AdminDashboard(),
          DoctorsListScreen.routeName: (_) => const DoctorsListScreen(),
          BookAppointmentScreen.routeName: (_) => const BookAppointmentScreen(),
          MyAppointmentsScreen.routeName: (_) => const MyAppointmentsScreen(),
          QueueScreen.routeName: (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return QueueScreen(appointmentId: args['appointmentId']);
          },
          DoctorScheduleScreen.routeName: (_) => const DoctorScheduleScreen(),
          LiveQueueScreen.routeName: (context) {
            final doctorId = ModalRoute.of(context)!.settings.arguments as int;
            return LiveQueueScreen(doctorId: doctorId);
          },
          AdminQueueMonitorScreen.routeName: (_) => const AdminQueueMonitorScreen(),
          // New admin routes
          AdminStatsScreen.routeName: (_) => const AdminStatsScreen(),
          AdminAppointmentsScreen.routeName: (_) => const AdminAppointmentsScreen(),
          AdminUsersScreen.routeName: (_) => const AdminUsersScreen(),
          AdminReportsScreen.routeName: (_) => const AdminReportsScreen(),
          AdminManageSlotsScreen.routeName: (_) => const AdminManageSlotsScreen(),
        },
      ),
    );
  }
}
