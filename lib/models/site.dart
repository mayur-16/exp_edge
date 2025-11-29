class Site {
  final String id;
  final String organizationId;
  final String name;
  final String? location;
  final DateTime? startDate;
  final String status;
  final DateTime createdAt;

  Site({
    required this.id,
    required this.organizationId,
    required this.name,
    this.location,
    this.startDate,
    required this.status,
    required this.createdAt,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['id'],
      organizationId: json['organization_id'],
      name: json['name'],
      location: json['location'],
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date']) 
          : null,
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organization_id': organizationId,
      'name': name,
      'location': location,
      'start_date': startDate?.toIso8601String().split('T')[0],
      'status': status,
    };
  }
}