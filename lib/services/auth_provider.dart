import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthUser {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? companyName;
  final String? city;
  final String? state;
  final String? bio;
  final String? skills;
  final int? experienceYears;
  final String? currentCompany;

  AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.companyName,
    this.city,
    this.state,
    this.bio,
    this.skills,
    this.experienceYears,
    this.currentCompany,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'],
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone'],
    role: json['role'] ?? 'jobseeker',
    companyName: json['company_name'],
    city: json['city'],
    state: json['state'],
    bio: json['bio'],
    skills: json['skills'],
    experienceYears: json['experience_years'],
    currentCompany: json['current_company'],
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email, 'phone': phone,
    'role': role, 'company_name': companyName, 'city': city,
    'state': state, 'bio': bio, 'skills': skills,
    'experience_years': experienceYears, 'current_company': currentCompany,
  };

  bool get isEmployer => role == 'employer' || role == 'hr';
  bool get isJobseeker => role == 'jobseeker';

  List<String> get skillsList =>
    skills?.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList() ?? [];
}

class AuthProvider extends ChangeNotifier {
  AuthUser? _user;
  bool _loading = true;
  String? _error;

  AuthUser? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Future<void> init() async {
    _loading = true;
    await ApiService.init();
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('user');
    if (stored != null) {
      try {
        _user = AuthUser.fromJson(jsonDecode(stored));
        // Verify token is still valid. Backend `/auth/me` returns the user
        // object directly (see server/routes/auth.js line ~136).
        if (ApiService.currentToken != null) {
          final data = await ApiService.getMe();
          _user = AuthUser.fromJson(data);
          await prefs.setString('user', jsonEncode(_user!.toJson()));
        }
      } catch (_) {
        // Token expired, malformed, or backend unreachable — clear local state
        _user = null;
        await ApiService.clearToken();
      }
    }
    _loading = false;
    notifyListeners();
  }

  /// Force refresh user data from server. Useful after profile update.
  Future<void> refreshUser() async {
    if (ApiService.currentToken == null) return;
    try {
      final data = await ApiService.getMe();
      _user = AuthUser.fromJson(data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(_user!.toJson()));
      notifyListeners();
    } catch (_) {
      // Silently fail — user may be offline
    }
  }

  Future<void> login(String email, String password) async {
    _error = null;
    try {
      final data = await ApiService.login(email, password);
      final token = data['token'] as String;
      await ApiService.setToken(token);
      _user = AuthUser.fromJson(data['user']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(_user!.toJson()));
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    }
  }

  Future<void> register(Map<String, dynamic> data) async {
    _error = null;
    try {
      final res = await ApiService.register(data);
      final token = res['token'] as String;
      await ApiService.setToken(token);
      _user = AuthUser.fromJson(res['user']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(_user!.toJson()));
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    }
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    _user = null;
    notifyListeners();
  }

  Future<void> updateUser(Map<String, dynamic> updates) async {
    if (_user == null) return;
    try {
      final data = await ApiService.updateProfile(updates);
      // Backend PUT /auth/profile returns the updated user object directly
      _user = AuthUser.fromJson(data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(_user!.toJson()));
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    }
  }
}
