class Vendor {
  final String id;
  final String organizationId;
  final String name;
  final String? contactNumber;
  final String? email;
  final String? address;
  final String? vendorType;
  final DateTime createdAt;

  Vendor({
    required this.id,
    required this.organizationId,
    required this.name,
    this.contactNumber,
    this.email,
    this.address,
    this.vendorType,
    required this.createdAt,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'],
      organizationId: json['organization_id'],
      name: json['name'],
      contactNumber: json['contact_number'],
      email: json['email'],
      address: json['address'],
      vendorType: json['vendor_type'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organization_id': organizationId,
      'name': name,
      'contact_number': contactNumber,
      'email': email,
      'address': address,
      'vendor_type': vendorType,
    };
  }
}