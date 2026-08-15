class HospitalModel {
  final String id;
  final String name;
  final String contact;
  final double lat;
  final double lng;
  final double? distance;

  HospitalModel({
    required this.id,
    required this.name,
    required this.contact,
    required this.lat,
    required this.lng,
    this.distance,
  });

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>? ?? {'lat': 0.0, 'lng': 0.0};
    return HospitalModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      contact: json['contact'] ?? '',
      lat: (loc['lat'] as num).toDouble(),
      lng: (loc['lng'] as num).toDouble(),
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
    );
  }
}
