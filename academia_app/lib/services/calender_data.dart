import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarCache {
  static Map<String, Map<String, dynamic>>? lastData;
  static DateTime? lastRefresh;
  static const Duration cacheDuration = Duration(minutes: 10); // Cache limit
}

/// Fetch calendar events with caching logic
Future<Map<String, Map<String, dynamic>>> getEventsData() async {
  final prefs = await SharedPreferences.getInstance();

  // ✅ 1. Return cached data if fresh (in-memory)
  if (CalendarCache.lastData != null &&
      CalendarCache.lastRefresh != null &&
      DateTime.now().difference(CalendarCache.lastRefresh!) <
          CalendarCache.cacheDuration) {
    print('⚡ Using cached calendar data (no Firestore call)');
    return CalendarCache.lastData!;
  }

  // ✅ 2. Try loading from SharedPreferences if exists
  final String? cachedJson = prefs.getString('calendar_cache');
  final int? cachedTime = prefs.getInt('calendar_cache_time');

  if (cachedJson != null && cachedTime != null) {
    final savedTime = DateTime.fromMillisecondsSinceEpoch(cachedTime);

    if (DateTime.now().difference(savedTime) < CalendarCache.cacheDuration) {
      print('📦 Using SharedPreferences calendar cache');

      final decoded = (jsonDecode(cachedJson) as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
      );

      CalendarCache.lastData = decoded;
      CalendarCache.lastRefresh = savedTime;
      return decoded;
    }
  }

  print('☁ Fetching calendar data from Firestore...');
  final FirebaseFirestore db = FirebaseFirestore.instance;
  Map<String, Map<String, dynamic>> eventsData = {};

  try {
    final connectivity = await Connectivity().checkConnectivity();
    bool isOffline = connectivity == ConnectivityResult.none;

    final snapshot = await db.collection('calendar').get(
      GetOptions(
        source: isOffline ? Source.cache : Source.serverAndCache,
      ),
    );

    for (var doc in snapshot.docs) {
      eventsData[doc.id] = Map<String, dynamic>.from(doc.data() as Map);
    }

    if (eventsData.isEmpty) {
      print(isOffline
          ? '⚠️ No cached calendar data found (offline).'
          : '⚠️ No calendar data found in Firestore.');
    } else {
      print('✅ Calendar data fetched from ${isOffline ? 'cache' : 'server/cache'}.');

      // ✅ Cache in memory
      CalendarCache.lastData = eventsData;
      CalendarCache.lastRefresh = DateTime.now();

      // ✅ Also store in SharedPreferences
      await prefs.setString('calendar_cache', jsonEncode(eventsData));
      await prefs.setInt('calendar_cache_time', DateTime.now().millisecondsSinceEpoch);
    }
  } catch (e) {
    print('❌ Error fetching Firestore data: $e');

    if (CalendarCache.lastData != null) {
      print('⚠ Using previous cached calendar data.');
      return CalendarCache.lastData!;
    }
  }

  return eventsData;
}
