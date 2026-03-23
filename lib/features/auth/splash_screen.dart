// Splash Screen
// Initial loading screen with JWT validation and role-based routing
// Handles authentication state and redirects to appropriate dashboard

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import 'auth_provider.dart';
import 'login_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../doctor/doctor_dashboard_screen.dart';
import '../patient/patient_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = AppConstants.splashRoute;
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2)); // Minimum splash time

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    // Check if user is logged in and token is valid
    final isAuthenticated = await authProvider.checkAuthStatus();

    if (!mounted) return;

    if (!isAuthenticated) {
      // Navigate to login if not authenticated
      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
      return;
    }

    // Navigate based on user role
    final userRole = authProvider.user?.role ?? 'patient';

    switch (userRole.toLowerCase()) {
      case 'admin':
        Navigator.of(context).pushReplacementNamed(AdminDashboard.routeName);
        break;
      case 'doctor':
        Navigator.of(context).pushReplacementNamed(DoctorDashboard.routeName);
        break;
      case 'patient':
      default:
        Navigator.of(context).pushReplacementNamed(PatientDashboard.routeName);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1976D2), // Blue
              Color(0xFF42A5F5), // Light Blue
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_hospital,
                  size: 60,
                  color: Color(0xFF1976D2),
                ),
              ),

              const SizedBox(height: 32),

              // App Name
              const Text(
                'MedQueue GH',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 8),

              // Tagline
              const Text(
                'Hospital Queue Management System',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Loading Indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),

              const SizedBox(height: 16),

              // Loading Text
              const Text(
                'Initializing...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Comments for academic documentation:
// - SplashScreen: Professional loading screen with authentication validation
// - JWT token validation on app startup
// - Role-based routing to appropriate dashboards
// - Medical-themed design with hospital icon
// - Gradient background for visual appeal
// - Minimum display time for branding