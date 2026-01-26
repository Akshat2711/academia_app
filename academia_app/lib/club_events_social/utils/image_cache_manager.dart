import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Utility class for managing image caching with optimized memory usage
class ImageCacheManager {
  static final DefaultCacheManager _cacheManager = DefaultCacheManager();

  /// Pre-cache an image for faster loading later
  static Future<void> preCacheImage(String imageUrl) async {
    try {
      await _cacheManager.getSingleFile(imageUrl);
    } catch (e) {
      // Silently fail on caching errors
    }
  }

  /// Pre-cache multiple images (useful for cards about to be visible)
  static Future<void> preCacheImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      await preCacheImage(url);
    }
  }

  /// Clear old cached images to manage memory
  static Future<void> clearOldCache() async {
    try {
      await _cacheManager.emptyCache();
    } catch (e) {
      // Silently fail on cache clear errors
    }
  }

  /// Get the cache manager instance for advanced operations
  static DefaultCacheManager getCacheManager() => _cacheManager;

  /// Get cache file directly
  static Future<String?> getCachedImagePath(String imageUrl) async {
    try {
      final file = await _cacheManager.getSingleFile(imageUrl);
      return file.path;
    } catch (e) {
      return null;
    }
  }
}
