import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VideoCache {
  static const String urlKey = "profile_video_url";
  static const String timeKey = "profile_video_time";
  static const Duration cacheDuration = Duration(hours: 24);

  // in-memory cache
  static String? memoryUrl;
  static DateTime? memoryTime;
}

Future<String?> getProfileCardVideoUrl() async {
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime.now();

  // 🔹 1. MEMORY cache (fastest)
  if (VideoCache.memoryUrl != null &&
      VideoCache.memoryTime != null &&
      now.difference(VideoCache.memoryTime!) <
          VideoCache.cacheDuration) {
    print("⚡ Using memory cache");
    return VideoCache.memoryUrl;
  }

  // 🔹 2. PERSISTENT cache
  final cachedUrl = prefs.getString(VideoCache.urlKey);
  final cachedTime = prefs.getInt(VideoCache.timeKey);

  if (cachedUrl != null && cachedTime != null) {
    final savedTime =
        DateTime.fromMillisecondsSinceEpoch(cachedTime);

    if (now.difference(savedTime) <
        VideoCache.cacheDuration) {
      print("📦 Using persistent cache");

      // update memory cache
      VideoCache.memoryUrl = cachedUrl;
      VideoCache.memoryTime = savedTime;

      return cachedUrl;
    }
  }

  // 🔴 3. Fetch from Firestore ONLY if needed
  print("☁ Fetching from Firestore...");
  final db = FirebaseFirestore.instance;

  try {
    final doc = await db
        .collection('essentials')
        .doc('profile_card_video')
        .get(const GetOptions(source: Source.server));

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final url = data['link'] as String?;

      if (url != null && url.isNotEmpty) {
        // 🔹 Save persistent cache
        await prefs.setString(VideoCache.urlKey, url);
        await prefs.setInt(
            VideoCache.timeKey, now.millisecondsSinceEpoch);

        // 🔹 Update memory cache
        VideoCache.memoryUrl = url;
        VideoCache.memoryTime = now;

        print("✅ Video URL saved (persistent + memory)");
        return url;
      }
    }

    print("⚠ No valid video URL found");

  } catch (e) {
    print("❌ Firestore fetch failed: $e");

    // 🔹 fallback to stale cache
    if (cachedUrl != null) {
      print("⚠ Using stale cached URL");
      return cachedUrl;
    }
  }

  return null;
}