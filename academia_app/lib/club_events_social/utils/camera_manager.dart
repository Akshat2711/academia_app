import 'dart:io';
import 'package:image_picker/image_picker.dart';

class MediaHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Captures multiple images from the camera sequentially.
  /// It opens the camera, and after each shot, it asks if you want to take another
  /// until the user cancels or finishes.
  static Future<List<File>> captureMultipleImagesFromCamera() async {
    List<File> capturedImages = [];
    bool continueCapturing = true;

    while (continueCapturing) {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Optimized for upload
      );

      if (photo != null) {
        capturedImages.add(File(photo.path));
        // Note: In a real app, you might want a custom overlay, 
        // but sequential triggers are the standard with image_picker.
      } else {
        // User cancelled the camera
        continueCapturing = false;
      }
      
      // Optional: Add a limit to prevent infinite loops
      if (capturedImages.length >= 10) continueCapturing = false;
    }

    return capturedImages;
  }
}