import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

typedef AnnouncementMap = Map<String, dynamic>;

class AnnouncementCache {
  static Map<String, AnnouncementMap>? lastData;
  static DateTime? lastRefresh;
  static const Duration cacheDuration = Duration(minutes: 30); // ✅ Set cache time
}

Future<Map<String, AnnouncementMap>> getEventsData() async {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // ✅ If data exists AND last refresh was within 10 min → Return cached data
  if (AnnouncementCache.lastData != null &&
      AnnouncementCache.lastRefresh != null &&
      DateTime.now().difference(AnnouncementCache.lastRefresh!) <
          AnnouncementCache.cacheDuration) {
    print("⚡ Using cached announcement data (no Firestore call)");
    return AnnouncementCache.lastData!;
  }

  print("☁ Fetching announcement data from Firestore...");

  Map<String, AnnouncementMap> eventsData = {};

  try {
    final connectivity = await Connectivity().checkConnectivity();
    bool isOffline = connectivity == ConnectivityResult.none;

    final snapshot = await db.collection('announcement').get(
      GetOptions(
        source: isOffline ? Source.cache : Source.serverAndCache,
      ),
    );

    for (var doc in snapshot.docs) {
      eventsData[doc.id] = Map<String, dynamic>.from(doc.data() as Map);
    }

    // ✅ Save to cache
    AnnouncementCache.lastData = eventsData;
    AnnouncementCache.lastRefresh = DateTime.now();

    print("✅ Data refreshed from ${isOffline ? 'cache' : 'server/cache'}");

  } catch (e) {
    print("❌ Error during fetch: $e");

    // ✅ If fetch fails but we have cache → return that instead of empty
    if (AnnouncementCache.lastData != null) {
      print("⚠ Using previous cached data due to error");
      return AnnouncementCache.lastData!;
    }
  }

  return eventsData;
}
