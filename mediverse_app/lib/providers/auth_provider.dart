import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mediverse_app/models/user_model.dart';
import 'package:mediverse_app/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null && _currentUser != null;

  // Load stored token on app launch
  Future<bool> loadSession() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final savedToken = await _apiService.getToken();
    if (savedToken == null) {
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final response = await _apiService.get('/users/profile');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _currentUser = UserModel.fromJson(data);
        _token = savedToken;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        await _apiService.clearToken();
      }
    } catch (e) {
      _errorMessage = "Network connection failed. Offline mode active.";
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Handle Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        _token = data['token'];
        _currentUser = UserModel.fromJson(data['user']);
        await _apiService.saveToken(_token!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['error'] ?? 'Login failed.';
      }
    } catch (e) {
      _errorMessage = "Server connection refused. Check backend status.";
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Handle Google / Gmail Authentication
  Future<bool> loginWithGoogle({
    required String email,
    required String name,
    String? googleId,
    String? avatar,
    String role = 'patient',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/google', {
        'email': email,
        'name': name,
        'google_id': googleId ?? 'google_${DateTime.now().millisecondsSinceEpoch}',
        'avatar': avatar ?? '',
        'role': role,
      });

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        _token = data['token'];
        _currentUser = UserModel.fromJson(data['user']);
        await _apiService.saveToken(_token!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['error'] ?? 'Google authentication failed.';
      }
    } catch (e) {
      _errorMessage = "Server connection refused. Check backend status.";
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Simulated Biometric Quick Login

  Future<bool> authenticateBiometric() async {
    _isLoading = true;
    notifyListeners();
    
    // Simulate slight sensor delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    final savedToken = await _apiService.getToken();
    if (savedToken != null) {
      final success = await loadSession();
      _isLoading = false;
      return success;
    }
    
    _errorMessage = "No session found. Please login with password first.";
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Handle Registration
  Future<bool> register({
    required String role,
    required String name,
    required String email,
    required String password,
    required String phone,
    required Map<String, double> location,
    String? bloodGroup,
    String? specialization,
    String? qualifications,
    int? experience,
    String? bio,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final body = {
      'role': role,
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'location': location,
      if (bloodGroup != null) 'blood_group': bloodGroup,
      if (specialization != null) 'specialization': specialization,
      if (qualifications != null) 'qualifications': qualifications,
      if (experience != null) 'experience': experience,
      if (bio != null) 'bio': bio,
    };

    try {
      final response = await _apiService.post('/auth/register', body);
      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        _token = data['token'];
        _currentUser = UserModel.fromJson(data['user']);
        await _apiService.saveToken(_token!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['error'] ?? 'Registration failed.';
      }
    } catch (e) {
      _errorMessage = "Could not reach registration servers.";
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Handle Logout
  Future<void> logout() async {
    await _apiService.clearToken();
    _token = null;
    _currentUser = null;
    notifyListeners();
  }
}
