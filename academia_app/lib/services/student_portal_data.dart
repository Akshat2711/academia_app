import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class student_portal_Service {
  static const String _url =
      "https://academia-scrapper-api-fast.onrender.com/studentportal_result";

  /// Fetch student portal result using netId + password
  /// Stores successful response in local storage
  /// Returns a structured result:
  ///
  /// {
  ///    "success": true/false,
  ///    "data": Map or null,
  ///    "error": String or null
  /// }
  static Future<Map<String, dynamic>> fetchStudentPortalResult(
      String netId, String password) async {
    try {
      final body = jsonEncode({
        "netid": netId,
        "password": password,
      });

      final response = await http.post(
        Uri.parse(_url),
        headers: {
          "accept": "application/json",
          "Content-Type": "application/json",
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Store in local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("student_portal_result", jsonEncode(data));

        return {
          "success": true,
          "data": data,
          "error": null,
        };
      } else {
        return {
          "success": false,
          "data": null,
          "error": "Server responded with status ${response.statusCode}",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "data": null,
        "error": e.toString(),
      };
    }
  }

  /// Get cached result (if exists)
  static Future<Map<String, dynamic>?> getCachedResult() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString("student_portal_result");
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  /// Clear saved result
  static Future<void> clearResult() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("student_portal_result");
  }
}
