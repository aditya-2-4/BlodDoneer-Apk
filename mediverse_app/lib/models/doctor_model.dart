class DoctorModel {
  final String id;
  final String userId;
  final String name;
  final String specialization;
  final String qualifications;
  final int experience;
  final String hospitalName;
  final List<String> availableSlots;
  final String licenseNumber;
  final String consultFee;
  final double rating;
  final int reviewsCount;
  final String bio;
  final double lat;
  final double lng;
  final double? distance;

  DoctorModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.specialization,
    required this.qualifications,
    required this.experience,
    required this.hospitalName,
    required this.availableSlots,
    required this.licenseNumber,
    required this.consultFee,
    required this.rating,
    required this.reviewsCount,
    required this.bio,
    required this.lat,
    required this.lng,
    this.distance,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>? ?? {'lat': 0.0, 'lng': 0.0};
    return DoctorModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? 'Dr. Staff',
      specialization: json['specialization'] ?? '',
      qualifications: json['qualifications'] ?? '',
      experience: json['experience'] ?? 0,
      hospitalName: json['hospital_name'] ?? 'General Clinic',
      availableSlots: List<String>.from(json['available_slots'] ?? []),
      licenseNumber: json['license_number'] ?? 'MCI-00000',
      consultFee: json['consult_fee'] ?? '\$30',
      rating: (json['rating'] as num? ?? 4.8).toDouble(),
      reviewsCount: json['reviews_count'] ?? 50,
      bio: json['bio'] ?? '',
      lat: (loc['lat'] as num).toDouble(),
      lng: (loc['lng'] as num).toDouble(),
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
    );
  }
}
