# MedQueue GH - Hospital Queue Management System

## Overview

MedQueue GH is a comprehensive hospital queue management system designed to streamline patient appointment scheduling, reduce wait times, and improve healthcare service delivery in Ghana. The system features role-based access for patients, doctors, and administrators, with integrated AI chatbot support, WhatsApp notifications, and real-time queue monitoring.

## Features

### Patient Features
- **User Registration & Authentication**: Secure OTP-based registration
- **Doctor Discovery**: Browse and select doctors by specialty and location
- **Appointment Booking**: Real-time slot booking with Google Maps integration
- **Queue Monitoring**: Live queue position tracking with estimated wait times
- **Appointment Management**: View, reschedule, and cancel appointments
- **Notifications**: Firebase push notifications and WhatsApp alerts

### Doctor Features
- **Schedule Management**: Set availability slots and manage working hours
- **Live Queue**: Real-time patient queue with position updates
- **Patient Management**: View patient details and appointment history
- **Status Updates**: Mark patients as completed or no-show

### Admin Features
- **Dashboard Analytics**: Comprehensive statistics and KPIs
- **User Management**: Manage patients, doctors, and admin accounts
- **Appointment Oversight**: Monitor and modify all appointments
- **Slot Management**: Create and manage doctor availability slots
- **System Reports**: No-show rates and queue performance analytics
- **Security Monitoring**: Audit logs and system security

### System Features
- **AI Chatbot**: OpenAI-powered conversational assistant
- **Multi-channel Notifications**: WhatsApp and Firebase messaging
- **Location Services**: Google Maps integration for location-based features
- **Security**: JWT authentication, rate limiting, input validation
- **Real-time Updates**: Live queue positions and status changes

## Technology Stack

### Backend
- **Node.js** with Express.js framework
- **MySQL** database with connection pooling
- **JWT** for authentication and authorization
- **bcrypt** for password hashing
- **express-validator** for input sanitization
- **helmet** for security headers
- **express-rate-limit** for API protection
- **Twilio** for WhatsApp integration
- **Firebase Admin SDK** for push notifications
- **OpenAI API** for chatbot functionality

### Frontend
- **Flutter** cross-platform framework
- **Dart** programming language
- **Provider** for state management
- **Material Design** UI components
- **Google Maps Flutter** for location services
- **FL Chart** for data visualization
- **Flutter Secure Storage** for token management

### External Services
- **Twilio**: WhatsApp messaging
- **Firebase**: Push notifications
- **OpenAI**: AI chatbot
- **Google Maps**: Location services

## Project Structure

```
medqueue/
├── lib/
│   ├── core/
│   │   ├── app_theme.dart          # Application theming
│   │   ├── constants.dart          # App constants and routes
│   │   ├── widgets/
│   │   │   ├── error_snackbar.dart # Error display widget
│   │   │   └── loading_button.dart # Loading button widget
│   ├── features/
│   │   ├── auth/
│   │   │   ├── auth_provider.dart   # Authentication state
│   │   │   ├── login_screen.dart    # Login interface
│   │   │   ├── register_screen.dart # Registration interface
│   │   │   ├── otp_screen.dart      # OTP verification
│   │   │   └── splash_screen.dart   # Loading screen
│   │   ├── admin/
│   │   │   ├── admin_dashboard_screen.dart     # Admin dashboard
│   │   │   ├── admin_stats_screen.dart         # Statistics with charts
│   │   │   ├── admin_appointments_screen.dart  # Appointment management
│   │   │   ├── admin_users_screen.dart         # User management
│   │   │   ├── admin_reports_screen.dart       # System reports
│   │   │   └── admin_manage_slots_screen.dart  # Slot management
│   │   ├── doctor/
│   │   │   ├── doctor_dashboard_screen.dart    # Doctor dashboard
│   │   │   ├── doctor_schedule_screen.dart     # Schedule management
│   │   │   └── live_queue_screen.dart          # Live queue view
│   │   └── patient/
│   │       ├── patient_dashboard_screen.dart   # Patient dashboard
│   │       ├── doctors_list_screen.dart        # Doctor selection
│   │       ├── book_appointment_screen.dart    # Appointment booking
│   │       ├── my_appointments_screen.dart     # Appointment history
│   │       └── queue_screen.dart               # Queue monitoring
│   ├── models/
│   │   ├── user_model.dart         # User data model
│   │   ├── doctor_model.dart       # Doctor data model
│   │   ├── appointment_model.dart  # Appointment data model
│   └── services/
│       ├── auth_service.dart       # Authentication API client
│       ├── admin_service.dart      # Admin API client
│       └── queue_service.dart      # Queue management service
├── backend/
│   ├── routes/
│   │   ├── auth.js                 # Authentication endpoints
│   │   ├── admin.js                # Admin endpoints
│   │   ├── appointments.js         # Appointment endpoints
│   │   └── queue.js                # Queue endpoints
│   ├── models/
│   │   ├── User.js                 # User database model
│   │   ├── Appointment.js          # Appointment database model
│   │   └── AuditLog.js             # Audit logging model
│   ├── utils/
│   │   ├── auditLog.js             # Audit logging utility
│   │   └── validation.js           # Input validation utilities
│   ├── middleware/
│   │   ├── auth.js                 # JWT authentication middleware
│   │   ├── validation.js           # Request validation middleware
│   │   └── security.js             # Security middleware
│   ├── config/
│   │   └── database.js             # Database configuration
│   └── server.js                   # Main server file
├── android/                        # Android platform files
├── ios/                           # iOS platform files
├── web/                           # Web platform files
├── test/                          # Unit and integration tests
├── pubspec.yaml                   # Flutter dependencies
├── package.json                   # Node.js dependencies
├── .env.example                   # Environment variables template
└── README.md                      # This file
```

## Installation & Setup

### Prerequisites
- **Flutter SDK** (version 3.0 or higher)
- **Node.js** (version 16 or higher)
- **MySQL** (version 8.0 or higher)
- **Android Studio** (for Android development)
- **Xcode** (for iOS development, macOS only)

### Backend Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/medqueue-gh.git
   cd medqueue-gh/backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Database setup**
   ```bash
   # Create MySQL database
   mysql -u root -p
   CREATE DATABASE medqueue_db;
   EXIT;

   # Run database migrations
   npm run migrate
   ```

4. **Environment configuration**
   ```bash
   cp .env.example .env
   # Edit .env with your actual configuration values
   ```

5. **Start the server**
   ```bash
   npm start
   ```

### Frontend Setup

1. **Navigate to Flutter project**
   ```bash
   cd ../medqueue
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure platform-specific settings**
   ```bash
   # For Android
   flutter build apk --debug

   # For iOS (macOS only)
   flutter build ios --debug
   ```

4. **Run the application**
   ```bash
   flutter run
   ```

## API Documentation

### Authentication Endpoints
- `POST /api/auth/register` - User registration
- `POST /api/auth/verify-otp` - OTP verification
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout
- `GET /api/auth/validate` - Token validation

### Admin Endpoints
- `GET /api/admin/stats` - System statistics
- `GET /api/admin/appointments` - List appointments with filters
- `PATCH /api/admin/appointments/:id/status` - Update appointment status
- `GET /api/admin/users` - List users with filters
- `PATCH /api/admin/users/:id/status` - Update user status
- `GET /api/admin/reports/noshow` - No-show rate reports
- `GET /api/admin/reports/queue` - Queue performance reports
- `GET /api/admin/slots` - List doctor slots
- `POST /api/admin/slots` - Create new slot
- `DELETE /api/admin/slots/:id` - Delete slot

### Appointment Endpoints
- `GET /api/appointments` - List user appointments
- `POST /api/appointments` - Book new appointment
- `PATCH /api/appointments/:id` - Update appointment
- `DELETE /api/appointments/:id` - Cancel appointment

### Queue Endpoints
- `GET /api/queue/:appointmentId` - Get queue position
- `POST /api/queue/:appointmentId/checkin` - Check-in to queue
- `GET /api/queue/doctor/:doctorId` - Get doctor's live queue

## Security Features

- **JWT Authentication**: Secure token-based authentication
- **Password Hashing**: bcrypt with configurable rounds
- **Input Validation**: Comprehensive request validation
- **Rate Limiting**: API protection against abuse
- **Security Headers**: Helmet.js for HTTP security
- **Audit Logging**: Comprehensive security event logging
- **CORS Protection**: Configurable cross-origin policies

## Testing

### Backend Testing
```bash
cd backend
npm test
```

### Frontend Testing
```bash
cd medqueue
flutter test
```

### Integration Testing
```bash
# Run both backend and frontend tests
npm run test:integration
```

## Deployment

### Backend Deployment
```bash
# Production build
npm run build

# Start production server
npm run start:prod
```

### Frontend Deployment
```bash
# Build for Android
flutter build apk --release

# Build for iOS
flutter build ios --release

# Build for Web
flutter build web --release
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- **Ghana Health Service** for healthcare domain expertise
- **Flutter Community** for excellent cross-platform framework
- **OpenAI** for AI chatbot capabilities
- **Twilio** for communication services
- **Firebase** for reliable messaging infrastructure

## Contact

- **Project Lead**: [Your Name]
- **Email**: [your.email@example.com]
- **GitHub**: [https://github.com/your-username/medqueue-gh]

---

**MedQueue GH** - Transforming Healthcare Queue Management in Ghana 🇬🇭
