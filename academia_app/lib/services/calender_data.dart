import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Fetches all calendar events from Firestore.
/// - Returns data from Firestore if online.
/// - Falls back to cached data if offline.
/// - Returns an empty map if no cache or error.
Future<Map<String, Map<String, dynamic>>> getEventsData() async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  Map<String, Map<String, dynamic>> eventsData = {};

  try {
    // Check network status first
    final connectivity = await Connectivity().checkConnectivity();
    bool isOffline = connectivity == ConnectivityResult.none;

    // Try fetching data (prefer server if online, else cache)
    final snapshot = await db.collection('calendar').get(
      GetOptions(
        source: isOffline ? Source.cache : Source.serverAndCache,
      ),
    );

    // Convert Firestore snapshot into Map
    for (var doc in snapshot.docs) {
      eventsData[doc.id] = Map<String, dynamic>.from(doc.data() as Map);
    }

    if (eventsData.isEmpty) {
      if (isOffline) {
        print('⚠️ No cached calendar data found (offline).');
      } else {
        print('⚠️ No calendar data found in Firestore.');
      }
    } else {
      print('✅ Calendar data fetched from ${isOffline ? 'cache' : 'server/cache'}.');
    }
  } catch (e) {
    print('❌ Error fetching Firestore data: $e');
  }

  return eventsData;
}
