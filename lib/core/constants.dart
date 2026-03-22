// Application Constants
// Centralized configuration for URLs, endpoints, and app metadata
// Used across the entire Flutter application for consistency

class AppConstants {
  // App Information
  static const String appName = 'MedQueue GH';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Hospital Queue Management System for Ghana';

  // API Configuration
  static const String baseUrl = 'http://10.0.2.2:3000'; // Android emulator localhost
  // For physical device testing, use your computer's IP: 'http://192.168.1.XXX:3000'
  // For production: 'https://your-api-domain.com'

  // API Endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String logoutEndpoint = '/api/auth/logout';

  // Appointment Endpoints
  static const String bookAppointmentEndpoint = '/api/appointments/book';
  static const String myAppointmentsEndpoint = '/api/appointments/my';
  static const String cancelAppointmentEndpoint = '/api/appointments/cancel';
  static const String doctorScheduleEndpoint = '/api/appointments/doctor-schedule';
  static const String availableSlotsEndpoint = '/api/appointments/available-slots';

  // Queue Endpoints
  static const String joinQueueEndpoint = '/api/queue/join';
  static const String queueStatusEndpoint = '/api/queue/status';
  static const String leaveQueueEndpoint = '/api/queue/leave';

  // Chatbot Endpoints
  static const String chatbotMessageEndpoint = '/api/chatbot/message';
  static const String chatbotHistoryEndpoint = '/api/chatbot/history';

  // Emergency Endpoints
  static const String emergencySosEndpoint = '/api/emergency/sos';
  static const String emergencyActiveEndpoint = '/api/emergency/active';
  static const String emergencyStatusEndpoint = '/api/emergency/status';

  // Chat Endpoints
  static const String chatSendEndpoint = '/api/chat/send';
  static const String chatHistoryEndpoint = '/api/chat/history';
  static const String chatDoctorConversationsEndpoint = '/api/chat/doctor/conversations';

  // Admin Endpoints
  static const String adminStatsEndpoint = '/api/admin/stats';
  static const String adminAppointmentsEndpoint = '/api/admin/appointments';
  static const String adminUsersEndpoint = '/api/admin/users';
  static const String adminUserStatusEndpoint = '/api/admin/users';
  static const String adminNoshowReportEndpoint = '/api/admin/reports/noshow';
  static const String adminQueueReportEndpoint = '/api/admin/reports/queue';
  static const String adminCreateSlotsEndpoint = '/api/admin/doctors/slots';

  // Route Names
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String otpRoute = '/otp';
  static const String splashRoute = '/splash';
  static const String patientDashboardRoute = '/patient-dashboard';
  static const String doctorDashboardRoute = '/doctor-dashboard';
  static const String adminDashboardRoute = '/admin-dashboard';
  static const String doctorsListRoute = '/doctors-list';
  static const String bookAppointmentRoute = '/book-appointment';
  static const String myAppointmentsRoute = '/my-appointments';
  static const String queueRoute = '/queue';
  static const String doctorScheduleRoute = '/doctor-schedule';
  static const String liveQueueRoute = '/live-queue';
  static const String adminQueueMonitorRoute = '/admin-queue-monitor';
  static const String adminStatsRoute = '/admin-stats';
  static const String adminAppointmentsRoute = '/admin-appointments';
  static const String adminUsersRoute = '/admin-users';
  static const String adminReportsRoute = '/admin-reports';
  static const String adminManageSlotsRoute = '/admin-manage-slots';

  // User Roles
  static const String rolePatient = 'patient';
  static const String roleDoctor = 'doctor';
  static const String roleAdmin = 'admin';

  // Appointment Statuses
  static const String statusPending = 'pending';
  static const String statusConfirmed = 'confirmed';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  static const String statusNoShow = 'no_show';

  // Queue Statuses
  static const String queueWaiting = 'waiting';
  static const String queueInProgress = 'in_progress';
  static const String queueCompleted = 'completed';

  // Emergency Statuses
  static const String emergencyPending = 'pending';
  static const String emergencyDispatched = 'dispatched';
  static const String emergencyCompleted = 'completed';
  static const String emergencyCancelled = 'cancelled';

  // Chat Directions
  static const String chatPatientToDoctor = 'patient_to_doctor';
  static const String chatDoctorToPatient = 'doctor_to_patient';

  // Validation Constants
  static const int minPasswordLength = 8;
  static const int maxNameLength = 100;
  static const int maxPhoneLength = 15;
  static const int maxMessageLength = 1000;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const double defaultElevation = 2.0;

  // Time Constants
  static const int tokenExpiryCheckInterval = 300; // 5 minutes in seconds
  static const int apiTimeout = 30; // 30 seconds

  // Cache Keys
  static const String authTokenKey = 'auth_token';
  static const String userRoleKey = 'user_role';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';

  // Error Messages
  static const String networkError = 'Network connection error. Please check your internet connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unauthorizedError = 'Session expired. Please login again.';
  static const String validationError = 'Please check your input and try again.';
  static const String unknownError = 'An unexpected error occurred. Please try again.';

  // Success Messages
  static const String loginSuccess = 'Login successful';
  static const String registerSuccess = 'Registration successful';
  static const String appointmentBooked = 'Appointment booked successfully';
  static const String appointmentCancelled = 'Appointment cancelled successfully';
  static const String messageSent = 'Message sent successfully';

  // Route Names
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String otpRoute = '/otp';
  static const String splashRoute = '/splash';
  static const String patientDashboardRoute = '/patient-dashboard';
  static const String doctorDashboardRoute = '/doctor-dashboard';
  static const String adminDashboardRoute = '/admin-dashboard';
  static const String doctorsListRoute = '/doctors-list';
  static const String bookAppointmentRoute = '/book-appointment';
  static const String myAppointmentsRoute = '/my-appointments';
  static const String queueRoute = '/queue';
  static const String doctorScheduleRoute = '/doctor-schedule';
  static const String liveQueueRoute = '/live-queue';
  static const String adminQueueMonitorRoute = '/admin-queue-monitor';
  static const String adminStatsRoute = '/admin-stats';
  static const String adminAppointmentsRoute = '/admin-appointments';
  static const String adminUsersRoute = '/admin-users';
  static const String adminReportsRoute = '/admin-reports';
  static const String adminManageSlotsRoute = '/admin-manage-slots';
}

// Comments for academic documentation:
// - Centralized constants for maintainability and consistency
// - API endpoints organized by feature for easy reference
// - Validation rules and UI constants for standardization
// - Error and success messages for consistent user feedback
// - Route names for navigation consistency across the app