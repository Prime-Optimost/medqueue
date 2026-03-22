// Emergency Request Model
// Represents an emergency SOS request from a patient
// Used for admin monitoring and status management

class EmergencyRequest {
  final int id;
  final int patientId;
  final String patientName;
  final String patientPhone;
  final DateTime requestTime;
  final double latitude;
  final double longitude;
  final double? locationAccuracy;
  final String? description;
  final String status;
  final int? ambulanceId;
  final DateTime? responseTime;

  EmergencyRequest({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.requestTime,
    required this.latitude,
    required this.longitude,
    this.locationAccuracy,
    this.description,
    required this.status,
    this.ambulanceId,
    this.responseTime,
  });

  // Factory constructor for creating from API response
  factory EmergencyRequest.fromJson(Map<String, dynamic> json) {
    return EmergencyRequest(
      id: json['id'],
      patientId: json['patient_id'],
      patientName: json['patient_name'] ?? 'Unknown Patient',
      patientPhone: json['patient_phone'] ?? '',
      requestTime: DateTime.parse(json['request_time']),
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      locationAccuracy: json['location_accuracy']?.toDouble(),
      description: json['description'],
      status: json['status'],
      ambulanceId: json['ambulance_id'],
      responseTime: json['response_time'] != null ? DateTime.parse(json['response_time']) : null,
    );
  }

  // Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'patient_name': patientName,
      'patient_phone': patientPhone,
      'request_time': requestTime.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'location_accuracy': locationAccuracy,
      'description': description,
      'status': status,
      'ambulance_id': ambulanceId,
      'response_time': responseTime?.toIso8601String(),
    };
  }
}

// Comments for academic documentation:
// - EmergencyRequest: Data model for SOS emergency requests
// - Location data: GPS coordinates with accuracy information
// - Status tracking: Enum values for request lifecycle
// - Patient info: Links to patient details for contact
// - Timestamps: Request time and response time tracking
// - Ambulance assignment: Tracks which ambulance is dispatched
// - JSON serialization: For API communication