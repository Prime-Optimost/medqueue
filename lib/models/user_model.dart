// UserModel: Represents user account data in the MedQueue app.
class UserModel {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String email;
  final String role;
  bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'email': email,
        'role': role,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      isActive: json['is_active'] == null
          ? true
          : (json['is_active'] is int
              ? json['is_active'] == 1
              : json['is_active'].toString().toLowerCase() == 'true'),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
