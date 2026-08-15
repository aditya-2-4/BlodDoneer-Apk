class AppointmentModel {
  final String id;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String patientEmail;
  final String doctorId;
  final String doctorName;
  final String specialization;
  final String hospitalName;
  final String date;
  final String time;
  final String status;
  final String reason;

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.patientEmail,
    required this.doctorId,
    required this.doctorName,
    required this.specialization,
    required this.hospitalName,
    required this.date,
    required this.time,
    required this.status,
    required this.reason,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      patientName: json['patient_name'] ?? 'Patient',
      patientPhone: json['patient_phone'] ?? '',
      patientEmail: json['patient_email'] ?? '',
      doctorId: json['doctor_id'] ?? '',
      doctorName: json['doctor_name'] ?? 'Dr. Assigned',
      specialization: json['specialization'] ?? '',
      hospitalName: json['hospital_name'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      status: json['status'] ?? 'pending',
      reason: json['reason'] ?? 'General Consultation',
    );
  }
}
