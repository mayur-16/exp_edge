class UserModel {
  final String id;
  final String organizationId;
  final String email;
  final String fullName;
  final String role;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.organizationId,
    required this.email,
    required this.fullName,
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      organizationId: json['organization_id'],
      email: json['email'],
      fullName: json['full_name'],
      role: json['role'] ?? 'admin',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isAdmin => role == 'admin';
  bool get canEdit => role == 'admin' || role == 'manager';
}