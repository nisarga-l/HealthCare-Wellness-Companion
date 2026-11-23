import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://healthcare-wellness-companion-1.onrender.com/api';

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
  };

  static Map<String, String> authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  static Map<String, dynamic> _response(http.Response response) {
    dynamic body;

    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = {'message': response.body};
    }

    return {
      'statusCode': response.statusCode,
      'data': body,
    };
  }

  // REGISTER
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required int age,
    required String gender,
    required double height,
    required double weight,
    required double targetWeight,
    required String goal,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'age': age,
        'gender': gender,
        'height': height,
        'weight': weight,
        'targetWeight': targetWeight,
        'goal': goal,
      }),
    );

    return _response(response);
  }

  // LOGIN
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    return _response(response);
  }

  // FORGOT PASSWORD - GENERATE DEMO OTP
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: headers,
      body: jsonEncode({
        'email': email,
      }),
    );

    return _response(response);
  }

  // RESET PASSWORD
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: headers,
      body: jsonEncode({
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      }),
    );

    return _response(response);
  }

  // GET USER PROFILE
  static Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: authHeaders(token),
    );

    return _response(response);
  }

  // GET WELLNESS RECORDS
  static Future<List<dynamic>> getWellness(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/wellness'),
      headers: authHeaders(token),
    );

    final result = _response(response);

    if (response.statusCode == 200) {
      final data = result['data'];

      if (data is List) return data;

      if (data is Map && data['records'] is List) {
        return data['records'];
      }

      return [];
    }

    throw Exception(
      result['data'] is Map
          ? result['data']['message'] ??
              'Unable to load wellness records'
          : 'Unable to load wellness records',
    );
  }

  // ADD WELLNESS RECORD
  static Future<Map<String, dynamic>> addWellness({
    required String token,
    required String category,
    required double value,
    required String unit,
    required String notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wellness'),
      headers: authHeaders(token),
      body: jsonEncode({
        'category': category,
        'value': value,
        'unit': unit,
        'notes': notes,
      }),
    );

    return _response(response);
  }

  // UPDATE WELLNESS RECORD
  static Future<Map<String, dynamic>> updateWellness({
    required String token,
    required String id,
    required String category,
    required double value,
    required String unit,
    required String notes,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/wellness/$id'),
      headers: authHeaders(token),
      body: jsonEncode({
        'category': category,
        'value': value,
        'unit': unit,
        'notes': notes,
      }),
    );

    return _response(response);
  }

  // DELETE WELLNESS RECORD
  static Future<Map<String, dynamic>> deleteWellness({
    required String token,
    required String id,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/wellness/$id'),
      headers: authHeaders(token),
    );

    return _response(response);E
  }
}