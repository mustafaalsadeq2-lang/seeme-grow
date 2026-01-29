// lib/services/image_service.dart
//
// SeeMeGrow — Image Service (FINAL / Day 3)
// ----------------------------------------
// ✅ pickImage() -> String path
// ✅ pickImageBytes() -> Uint8List
// ✅ No storage
// ✅ iOS + Web safe

import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class ImageService {
  ImageService._();
  static final ImageService _instance = ImageService._();
  static ImageService instance() => _instance;

  final ImagePicker _picker = ImagePicker();

  /// Pick image and return file path
  Future<String?> pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    return picked?.path;
  }

  /// Pick image and return bytes (for web or previews)
  Future<Uint8List?> pickImageBytes() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return null;
    return await picked.readAsBytes();
  }
}
