import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mediverse_app/models/doctor_model.dart';
import 'package:mediverse_app/models/donor_model.dart';
import 'package:mediverse_app/models/hospital_model.dart';
import 'package:mediverse_app/models/appointment_model.dart';
import 'package:mediverse_app/services/api_service.dart';

class AppProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<DoctorModel> _doctors = [];
  List<DonorModel> _donors = [];
  List<HospitalModel> _hospitals = [];
  List<AppointmentModel> _appointments = [];
  List<Map<String, dynamic>> _sosRequests = [];
  
  // Custom mock notification stack for simulator push alerts
  final List<Map<String, String>> _mockNotifications = [];

  List<DoctorModel> get doctors => _doctors;
  List<DonorModel> get donors => _donors;
  List<HospitalModel> get hospitals => _hospitals;
  List<AppointmentModel> get appointments => _appointments;
  List<Map<String, dynamic>> get sosRequests => _sosRequests;
  List<Map<String, String>> get mockNotifications => _mockNotifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Search Doctors
  Future<void> fetchDoctors({
    String specialization = 'All',
    required double lat,
    required double lng,
    double radius = 10,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final endpoint = '/doctors?specialization=$specialization&lat=$lat&lng=$lng&radius=$radius';
      final response = await _apiService.get(endpoint);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        _doctors = data.map((d) => DoctorModel.fromJson(d)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching doctors: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // Search Donors
  Future<void> fetchDonors({
    String bloodGroup = 'All',
    required double lat,
    required double lng,
    double radius = 10,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final endpoint = '/donors?blood_group=$bloodGroup&lat=$lat&lng=$lng&radius=$radius';
      final response = await _apiService.get(endpoint);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        _donors = data.map((d) => DonorModel.fromJson(d)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching donors: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // Search Closest Emergency Hospitals
  Future<void> fetchHospitals({
    required double lat,
    required double lng,
    double radius = 15,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final endpoint = '/hospitals?lat=$lat&lng=$lng&radius=$radius';
      final response = await _apiService.get(endpoint);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        _hospitals = data.map((h) => HospitalModel.fromJson(h)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching hospitals: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // Fetch Appointments
  Future<void> fetchAppointments() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/appointments');
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        _appointments = data.map((a) => AppointmentModel.fromJson(a)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching appointments: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // Book Doctor Slot
  Future<bool> bookAppointment({
    required String doctorId,
    required String date,
    required String time,
    required String reason,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/appointments', {
        'doctor_id': doctorId,
        'date': date,
        'time': time,
        'reason': reason,
      });

      if (response.statusCode == 201) {
        _isLoading = false;
        fetchAppointments(); // Reload list
        triggerMockPushAlert("Booking Requested", "Your appointment request was submitted to the doctor.");
        return true;
      }
    } catch (e) {
      debugPrint("Error booking appointment: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Doctor Approve/Cancel
  Future<bool> updateAppointmentStatus(String apptId, String status) async {
    try {
      final response = await _apiService.post('/appointments/$apptId/status', {
        'status': status,
      });

      if (response.statusCode == 200) {
        fetchAppointments(); // Refresh
        triggerMockPushAlert("Status Updated", "Appointment request marked as $status.");
        return true;
      }
    } catch (e) {
      debugPrint("Error updating appointment: $e");
    }
    return false;
  }

  // Donor Fetch Matching Requests
  Future<void> fetchNearbySOSRequests() async {
    try {
      final response = await _apiService.get('/donors/requests');
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        _sosRequests = List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      debugPrint("Error fetching SOS requests: $e");
    }
  }

  // Broadcast SOS Blood Request
  Future<bool> requestBloodSOS({
    required String bloodGroup,
    required String urgency,
    required Map<String, double> location,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/blood-requests', {
        'blood_group': bloodGroup,
        'urgency': urgency,
        'location': location,
      });

      if (response.statusCode == 201) {
        _isLoading = false;
        triggerMockPushAlert("SOS Broadcast Sent", "Emergency blood SOS request has been published to nearby donors.");
        return true;
      }
    } catch (e) {
      debugPrint("Error publishing SOS request: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Admin Blood Request status
  Future<bool> resolveBloodSOS(String sosId, String status) async {
    try {
      final response = await _apiService.post('/blood-requests/$sosId/status', {
        'status': status,
      });
      if (response.statusCode == 200) {
        fetchNearbySOSRequests();
        return true;
      }
    } catch (e) {
      debugPrint("Error resolving blood request: $e");
    }
    return false;
  }

  // Simulated push notifications handler
  void triggerMockPushAlert(String title, String message) {
    _mockNotifications.insert(0, {
      "title": title,
      "message": message,
      "timestamp": DateTime.now().toIsoformatString(),
    });
    notifyListeners();
  }

  void clearNotifications() {
    _mockNotifications.clear();
    notifyListeners();
  }
}

extension on DateTime {
  String toIsoformatString() {
    return "${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
  }
}
