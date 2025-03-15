import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageUtils {
  /// Picks an image from gallery or camera
  static Future<File?> pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Simulates compressing an image file
  /// In a real implementation, we would use a library like flutter_image_compress
  static Future<File?> compressImage(File file, {int quality = 70}) async {
    try {
      // For now, we'll just return the original file
      // In a real implementation, we would compress the image
      return file;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  /// Encodes an image file to base64 string
  static Future<String?> encodeImageToBase64(File file) async {
    try {
      // First compress the image to reduce size
      final compressedFile = await compressImage(file);
      final fileToUse = compressedFile ?? file;
      
      final bytes = await fileToUse.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      debugPrint('Error encoding image to base64: $e');
      return null;
    }
  }

  /// Converts base64 string to Uint8List for displaying in Image.memory
  static Uint8List base64ToUint8List(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      debugPrint('Error decoding base64 to Uint8List: $e');
      // Return a small transparent image as fallback
      return Uint8List.fromList([]);
    }
  }

  /// Decodes a base64 string to an image widget
  static Widget base64ToImage(String base64String, {
    BoxFit fit = BoxFit.cover,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) {
    try {
      final Uint8List bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        fit: fit,
        errorBuilder: errorBuilder ?? (context, error, stackTrace) {
          return const Icon(
            Icons.broken_image,
            color: Colors.red,
            size: 50,
          );
        },
      );
    } catch (e) {
      debugPrint('Error decoding base64 to image: $e');
      if (errorBuilder != null) {
        // Create a BuildContext mock since we can't pass null
        // This is just a fallback that shouldn't normally be reached
        return const Icon(
          Icons.broken_image,
          color: Colors.red,
          size: 50,
        );
      }
      return const Icon(
        Icons.broken_image,
        color: Colors.red,
        size: 50,
      );
    }
  }
}
