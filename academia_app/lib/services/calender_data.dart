import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CalendarCache {
  static Map<String, Map<String, dynamic>>? lastData;
  static DateTime? lastRefresh;
  static const Duration cacheDuration = Duration(minutes: 10); // Cache limit
}

/// Fetch calendar events with caching logic
Future<Map<String, Map<String, dynamic>>> getEventsData() async {
  // ✅ Return cached data if fresh (within 10 min)
  if (CalendarCache.lastData != null &&
      CalendarCache.lastRefresh != null &&
      DateTime.now().difference(CalendarCache.lastRefresh!) <
          CalendarCache.cacheDuration) {
    print('⚡ Using cached calendar data (no Firestore call)');
    return CalendarCache.lastData!;
  }

  print('☁ Fetching calendar data from Firestore...');

  final FirebaseFirestore db = FirebaseFirestore.instance;
  Map<String, Map<String, dynamic>> eventsData = {};

  try {
    // Check connectivity
    final connectivity = await Connectivity().checkConnectivity();
    bool isOffline = connectivity == ConnectivityResult.none;

    // Fetch data from Firestore (server or cache)
    final snapshot = await db.collection('calendar').get(
      GetOptions(
        source: isOffline ? Source.cache : Source.serverAndCache,
      ),
    );

    // Process
    for (var doc in snapshot.docs) {
      eventsData[doc.id] = Map<String, dynamic>.from(doc.data() as Map);
    }

    if (eventsData.isEmpty) {
      print(isOffline
          ? '⚠️ No cached calendar data found (offline).'
          : '⚠️ No calendar data found in Firestore.');
    } else {
      print('✅ Calendar data fetched from ${isOffline ? 'cache' : 'server/cache'}.');

      // ✅ Cache it
      CalendarCache.lastData = eventsData;
      CalendarCache.lastRefresh = DateTime.now();
    }
  } catch (e) {
    print('❌ Error fetching Firestore data: $e');

    // ✅ Fallback to last cached data if available
    if (CalendarCache.lastData != null) {
      print('⚠ Using previous cached calendar data.');
      return CalendarCache.lastData!;
    }
  }

  return eventsData;
}
