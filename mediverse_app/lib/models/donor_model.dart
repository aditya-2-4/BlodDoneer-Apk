class DonorModel {
  final String id;
  final String userId;
  final String name;
  final String bloodGroup;
  final String lastDonated;
  final String availabilityStatus;
  final String phone;
  final double lat;
  final double lng;
  final double? distance;

  DonorModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.bloodGroup,
    required this.lastDonated,
    required this.availabilityStatus,
    required this.phone,
    required this.lat,
    required this.lng,
    this.distance,
  });

  factory DonorModel.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>? ?? {'lat': 0.0, 'lng': 0.0};
    return DonorModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? 'Donor',
      bloodGroup: json['blood_group'] ?? 'O+',
      lastDonated: json['last_donated'] ?? '',
      availabilityStatus: json['availability_status'] ?? 'available',
      phone: json['phone'] ?? '',
      lat: (loc['lat'] as num).toDouble(),
      lng: (loc['lng'] as num).toDouble(),
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
    );
  }
}
