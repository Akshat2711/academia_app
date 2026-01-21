import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/day_order_backup.dart';

class DataRefreshService {
  static Future<bool> refreshData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('userEmail');
      final password = prefs.getString('userPassword');

      if (email == null || password == null) {
        print("❌ Background refresh failed: no credentials");
        return false;
      }

      final url = Uri.parse('https://academia-scrapper-api-fast.onrender.com/scrape');
      final body = jsonEncode({"email": email, "password": password});

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode != 200) {
        print("❌ Background API failed: ${response.statusCode}");
        return false;
      }

      final data = jsonDecode(response.body);

      // --- Day Order handling ---
      int? dayOrder;
      if (data['attendance']?['day_order'] != null) {
        dayOrder = data['attendance']['day_order'] as int;

        await DayOrderManager.saveDayOrderData(
          currentDayOrder: dayOrder,
          currentDate: DateTime.now(),
        );
      } else {
        dayOrder = await DayOrderManager.getCurrentDayOrder();

        if (dayOrder != null) {
          data['attendance'] ??= {};
          data['attendance']['day_order'] = dayOrder;
        }
      }

      // Save user dashboard data
      await prefs.setString('userData', jsonEncode(data));

      // Save last refresh time
      await prefs.setString(
        'lastRefreshTime',
        DateTime.now().toIso8601String(),
      );

      print("✅ Background refresh success");
      return true;
    } catch (e) {
      print("❌ Background refresh error: $e");
      return false;
    }
  }
}
