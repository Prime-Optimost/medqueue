// AppointmentModel: Represents appointment data for patients and doctors.
class AppointmentModel {
  final int id;
  final String appointmentDate;
  final String appointmentTime;
  final String status;
  final String? reason;
  final String? notes;
  final String? doctorName;
  final String? specialization;
  final String? patientName;

  AppointmentModel({
    required this.id,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,
    this.reason,
    this.notes,
    this.doctorName,
    this.specialization,
    this.patientName,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      appointmentDate: json['appointment_date'],
      appointmentTime: json['appointment_time'],
      status: json['status'],
      reason: json['reason'],
      notes: json['notes'],
      doctorName: json['doctor_name'],
      specialization: json['specialization'],
      patientName: json['patient_name'],
    );
  }
}
