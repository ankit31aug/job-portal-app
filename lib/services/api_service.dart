import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// API Service — handles all HTTP calls to the Job Portal backend.
///
/// IMPORTANT: Endpoints below match the actual Express server in
/// `server/routes/*`. If your backend changes, update here.
///
/// Configure baseUrl for your environment:
/// - Production: 'https://your-api.com/api'
/// - Android emulator: 'http://10.0.2.2:5000/api'
/// - iOS simulator:    'http://localhost:5000/api'
class ApiService {
  static const String baseUrl = 'https://your-api-server.com/api';

  static String? _token;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  static String? get currentToken => _token;

  static Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static Map<String, String> get _bearerOnly => {
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ─── Auth ────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _jsonHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleObject(res);
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _jsonHeaders,
      body: jsonEncode(data),
    );
    return _handleObject(res);
  }

  static Future<Map<String, dynamic>> sendOtp(String email, String name) async {
    final res = await http.post(
      Uri.parse('$baseUrl/otp/send'),
      headers: _jsonHeaders,
      body: jsonEncode({'email': email, 'name': name}),
    );
    return _handleObject(res);
  }

  static Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final res = await http.post(
      Uri.parse('$baseUrl/otp/verify'),
      headers: _jsonHeaders,
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    return _handleObject(res);
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: _jsonHeaders,
      body: jsonEncode({'email': email}),
    );
    return _handleObject(res);
  }

  /// Backend `/api/auth/me` returns the user object directly (not wrapped).
  /// FIX BUG-F-4
  static Future<Map<String, dynamic>> getMe() async {
    final res = await http.get(Uri.parse('$baseUrl/auth/me'), headers: _bearerOnly);
    return _handleObject(res);
  }

  // ─── Jobs ────────────────────────────────────────────────────────────
  /// FIX BUG-F-6: backend expects single `experience` param like '1-5',
  /// not separate exp_min/exp_max.
  static Future<Map<String, dynamic>> getJobs({
    String? search,
    String? location,
    String? department,
    String? jobType,
    int? expMin,
    int? expMax,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (location != null && location.isNotEmpty) 'location': location,
      if (department != null && department != 'All') 'department': department,
      if (jobType != null && jobType.isNotEmpty) 'job_type': jobType,
    };
    if (expMin != null && expMax != null) {
      params['experience'] = '$expMin-$expMax';
    } else if (expMin != null) {
      params['experience'] = '$expMin';
    }
    final uri = Uri.parse('$baseUrl/jobs').replace(queryParameters: params);
    final res = await http.get(uri, headers: _bearerOnly);
    return _handleObject(res);
  }

  static Future<Map<String, dynamic>> getJob(int id) async {
    final res = await http.get(Uri.parse('$baseUrl/jobs/$id'), headers: _bearerOnly);
    return _handleObject(res);
  }

  static Future<Map<String, dynamic>> getJobStats() async {
    final res = await http.get(Uri.parse('$baseUrl/jobs/stats'), headers: _bearerOnly);
    return _handleObject(res);
  }

  static Future<Map<String, dynamic>> createJob(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/jobs'),
      headers: _jsonHeaders,
      body: jsonEncode(data),
    );
    return _handleObject(res);
  }

  // ─── Applications ────────────────────────────────────────────────────
  /// FIX BUG-F-8: backend returns array directly, not wrapped object.
  static Future<List<dynamic>> getMyApplications() async {
    final res = await http.get(Uri.parse('$baseUrl/applications/my'), headers: _bearerOnly);
    return _handleList(res);
  }

  /// FIX BUG-F-2: backend route is `POST /applications` with `job_id` in form,
  /// NOT `POST /applications/:jobId`.
  static Future<Map<String, dynamic>> applyToJob(
    int jobId,
    Map<String, dynamic> data,
    File? resumeFile,
  ) async {
    final uri = Uri.parse('$baseUrl/applications');
    final request = http.MultipartRequest('POST', uri);
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.fields['job_id'] = jobId.toString();
    data.forEach((k, v) {
      if (v != null) request.fields[k] = v.toString();
    });
    if (resumeFile != null) {
      request.files.add(await http.MultipartFile.fromPath('resume', resumeFile.path));
    }
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _handleObject(res);
  }

  static Future<List<dynamic>> getJobApplications(int jobId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/applications/job/$jobId'),
      headers: _bearerOnly,
    );
    return _handleList(res);
  }

  static Future<Map<String, dynamic>> updateApplicationStatus(
    int applicationId,
    String status,
  ) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/applications/$applicationId/status'),
      headers: _jsonHeaders,
      body: jsonEncode({'status': status}),
    );
    return _handleObject(res);
  }

  // ─── Bookmarks ───────────────────────────────────────────────────────
  /// Returns bookmarks as a List (backend returns array).
  static Future<List<dynamic>> getBookmarks() async {
    final res = await http.get(Uri.parse('$baseUrl/bookmarks'), headers: _bearerOnly);
    return _handleList(res);
  }

  static Future<bool> isBookmarked(int jobId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/bookmarks/check/$jobId'),
      headers: _bearerOnly,
    );
    final data = _handleObject(res);
    return data['bookmarked'] == true;
  }

  /// FIX BUG-F-3: backend has POST /bookmarks (with job_id in body) and
  /// DELETE /bookmarks/:jobId. There's NO toggle endpoint.
  static Future<bool> toggleBookmark(int jobId) async {
    final currently = await isBookmarked(jobId);
    if (currently) {
      final res = await http.delete(
        Uri.parse('$baseUrl/bookmarks/$jobId'),
        headers: _bearerOnly,
      );
      _handleObject(res);
      return false;
    } else {
      final res = await http.post(
        Uri.parse('$baseUrl/bookmarks'),
        headers: _jsonHeaders,
        body: jsonEncode({'job_id': jobId}),
      );
      _handleObject(res);
      return true;
    }
  }

  // ─── Profile ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    // Backend uses multipart for profile updates (supports resume upload)
    final uri = Uri.parse('$baseUrl/auth/profile');
    final request = http.MultipartRequest('PUT', uri);
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    data.forEach((k, v) {
      if (v != null) request.fields[k] = v.toString();
    });
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _handleObject(res);
  }

  // ─── Resume Match ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> matchResume(File resumeFile) async {
    final uri = Uri.parse('$baseUrl/resume/match');
    final request = http.MultipartRequest('POST', uri);
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.files.add(await http.MultipartFile.fromPath('resume', resumeFile.path));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _handleObject(res);
  }

  // ─── Boards (public) ─────────────────────────────────────────────────
  static Future<List<dynamic>> getBoards() async {
    final res = await http.get(Uri.parse('$baseUrl/boards'), headers: _bearerOnly);
    return _handleList(res);
  }

  // ─── Response handlers ───────────────────────────────────────────────
  static Map<String, dynamic> _handleObject(http.Response res) {
    final body = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (body is Map<String, dynamic>) return body;
      throw ApiException(statusCode: res.statusCode, message: 'Unexpected response shape');
    }
    throw ApiException(
      statusCode: res.statusCode,
      message: (body is Map ? (body['error'] ?? body['message']) : null) ??
        'Request failed (${res.statusCode})',
    );
  }

  static List<dynamic> _handleList(http.Response res) {
    final body = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (body is List) return body;
      // Some endpoints wrap in { jobs: [...] } or { applications: [...] }
      if (body is Map) {
        for (final key in const ['jobs', 'applications', 'bookmarks', 'data', 'items']) {
          if (body[key] is List) return body[key] as List;
        }
      }
      throw ApiException(statusCode: res.statusCode, message: 'Unexpected response shape');
    }
    throw ApiException(
      statusCode: res.statusCode,
      message: (body is Map ? (body['error'] ?? body['message']) : null) ??
        'Request failed (${res.statusCode})',
    );
  }

  static dynamic _decode(http.Response res) {
    if (res.body.isEmpty) return null;
    try {
      return jsonDecode(res.body);
    } catch (_) {
      return res.body;
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => message;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
}
