import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class VideoCache {
  static String? videoUrl;
  static DateTime? lastRefresh;

  static const Duration cacheDuration = Duration(hours: 24);
}

Future<String?> getProfileCardVideoUrl() async {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // ✅ Return cached value if within 24 hours
  if (VideoCache.videoUrl != null &&
      VideoCache.lastRefresh != null &&
      DateTime.now().difference(VideoCache.lastRefresh!) <
          VideoCache.cacheDuration) {
    print("⚡ Using cached video URL");
    return VideoCache.videoUrl;
  }

  print("☁ Fetching video URL from Firestore...");

  try {
    final connectivity = await Connectivity().checkConnectivity();
    bool isOffline = connectivity == ConnectivityResult.none;

    // 🔥 Your path: essentials/profile_card_video
    final doc = await db
        .collection('essentials')
        .doc('profile_card_video')
        .get(
          GetOptions(
            source: isOffline ? Source.cache : Source.serverAndCache,
          ),
        );

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final url = data['link'] as String?;

      if (url != null && url.isNotEmpty) {
        // ✅ Save to cache
        VideoCache.videoUrl = url;
        VideoCache.lastRefresh = DateTime.now();

        print("✅ Video URL fetched (${isOffline ? 'cache' : 'server/cache'})");
        return url;
      }
    }

    print("⚠ No valid video URL found in DB");

  } catch (e) {
    print("❌ Error fetching video URL: $e");

    // ✅ fallback to cache if exists
    if (VideoCache.videoUrl != null) {
      print("⚠ Using cached video URL due to error");
      return VideoCache.videoUrl;
    }
  }

  return null;
}