
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

  // ================= RESPONSE HANDLER =================

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

  // ================= REGISTER =================

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

  // ================= LOGIN =================

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

  // ================= FORGOT PASSWORD =================

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

  // ================= RESET PASSWORD =================

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

  // ================= GET PROFILE =================

  static Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: authHeaders(token),
    );

    return _response(response);
  }

  // ================= GET WELLNESS RECORDS =================

  static Future<List<dynamic>> getWellness(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/wellness'),
      headers: authHeaders(token),
    );

    final result = _response(response);

    if (response.statusCode == 200) {
      final data = result['data'];

      if (data is List) {
        return data;
      }

      if (data is Map && data['records'] is List) {
        return data['records'];
      }

      return [];
    }

    throw Exception(
      result['data'] is Map
          ? result['data']['message'] ?? 'Unable to load wellness records'
          : 'Unable to load wellness records',
    );
  }

  // ================= ADD WELLNESS RECORD =================

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

  // ================= UPDATE WELLNESS RECORD =================

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

  // ================= DELETE WELLNESS RECORD =================

  static Future<Map<String, dynamic>> deleteWellness({
    required String token,
    required String id,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/wellness/$id'),
      headers: authHeaders(token),
    );

    return _response(response);
  }

  // =====================================================
  //                    MEDICATION
  // =====================================================

  // GET MEDICATIONS

  static Future<Map<String, dynamic>> getMedications(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/medications'),
      headers: authHeaders(token),
    );

    return _response(response);
  }

  // ADD MEDICATION

  static Future<Map<String, dynamic>> addMedication({
    required String token,
    required Map<String, dynamic> medication,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/medications'),
      headers: authHeaders(token),
      body: jsonEncode(medication),
    );

    return _response(response);
  }

  // UPDATE MEDICATION

  static Future<Map<String, dynamic>> updateMedication({
    required String token,
    required String id,
    required Map<String, dynamic> medication,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/medications/$id'),
      headers: authHeaders(token),
      body: jsonEncode(medication),
    );

    return _response(response);
  }

  // DELETE MEDICATION

  static Future<Map<String, dynamic>> deleteMedication({
    required String token,
    required String id,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/medications/$id'),
      headers: authHeaders(token),
    );

    return _response(response);
  }

  // =====================================================
  //                 SMART HEALTH INSIGHTS
  // =====================================================

  // Get wellness records for analysis

  static Future<Map<String, dynamic>> getSmartInsights(
      String token,
      ) async {
    final records = await getWellness(token);

    double water = 0;
    double sleep = 0;
    double exercise = 0;

    for (final record in records) {
      if (record is! Map) continue;

      final category =
      (record['category'] ?? '').toString().toLowerCase();

      final value = double.tryParse(
        (record['value'] ?? 0).toString(),
      ) ?? 0;

      if (category.contains('water') ||
          category.contains('hydration')) {
        water += value;
      } else if (category.contains('sleep')) {
        sleep += value;
      } else if (category.contains('exercise') ||
          category.contains('workout') ||
          category.contains('activity')) {
        exercise += value;
      }
    }

    final List<String> insights = [];

    // Hydration Insight

    if (water < 2) {
      insights.add(
        'Your recorded water intake is low. Try drinking water regularly throughout the day.',
      );
    } else {
      insights.add(
        'Good hydration progress! Continue maintaining your water intake.',
      );
    }

    // Sleep Insight

    if (sleep < 7) {
      insights.add(
        'Your recorded sleep is below 7 hours. Try maintaining a consistent sleep schedule.',
      );
    } else {
      insights.add(
        'Your sleep duration looks good. Continue following a consistent sleep routine.',
      );
    }

    // Exercise Insight

    if (exercise < 30) {
      insights.add(
        'Try including at least 30 minutes of physical activity in your daily routine.',
      );
    } else {
      insights.add(
        'Great job staying physically active! Continue maintaining your activity routine.',
      );
    }

    return {
      'water': water,
      'sleep': sleep,
      'exercise': exercise,
      'totalRecords': records.length,
      'insights': insights,
    };
  }
}
