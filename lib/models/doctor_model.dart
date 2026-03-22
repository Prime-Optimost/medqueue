// DoctorModel: Represents doctor information for appointment booking.
class DoctorModel {
  final int id;
  final String fullName;
  final String specialization;
  final String availabilityStatus;
  final double consultationFee;

  DoctorModel({
    required this.id,
    required this.fullName,
    required this.specialization,
    required this.availabilityStatus,
    required this.consultationFee,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'],
      fullName: json['full_name'],
      specialization: json['specialization'] ?? '',
      availabilityStatus: json['availability_status'],
      consultationFee: (json['consultation_fee'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
