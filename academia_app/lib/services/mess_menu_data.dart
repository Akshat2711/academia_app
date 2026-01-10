import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

typedef MessMenuMap = Map<String, dynamic>;

class MessMenuCache {
  // Stores the entire nested JSON (sanasi and mblock)
  static MessMenuMap? lastData;
  static DateTime? lastRefresh;
  static const Duration cacheDuration = Duration(days:10); // ✅ cache for 10 days
}

class MessMenuService {
  static Future<MessMenuMap?> getMessMenu() async {
    final FirebaseFirestore db = FirebaseFirestore.instance;

    // 1. Check Memory Cache
    if (MessMenuCache.lastData != null &&
        MessMenuCache.lastRefresh != null &&
        DateTime.now().difference(MessMenuCache.lastRefresh!) <
            MessMenuCache.cacheDuration) {
      print("⚡ Using cached mess menu (Memory)");
      return MessMenuCache.lastData;
    }

    print("☁ Fetching mess menu from Firestore...");

    try {
      final connectivity = await Connectivity().checkConnectivity();
      bool isOffline = connectivity == ConnectivityResult.none;

      // 2. Fetch specific document 'messmenu' from 'mess' collection
      final docSnapshot = await db.collection('mess').doc('messmenu').get(
            GetOptions(
              source: isOffline ? Source.cache : Source.serverAndCache,
            ),
          );

      if (docSnapshot.exists) {
        MessMenuMap data = Map<String, dynamic>.from(docSnapshot.data()!);

        // 3. Update Cache
        MessMenuCache.lastData = data;
        MessMenuCache.lastRefresh = DateTime.now();

        print("✅ Mess menu refreshed from ${isOffline ? 'cache' : 'server'}");
        return data;
      }
    } catch (e) {
      print("❌ Error fetching mess menu: $e");

      // 4. Fallback to stale cache if server fetch fails
      if (MessMenuCache.lastData != null) {
        print("⚠ Using stale memory cache due to error");
        return MessMenuCache.lastData;
      }
    }

    return null;
  }
}