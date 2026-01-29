import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageFileService {
  static final ImagePicker _picker = ImagePicker();
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Offline-first:
  /// - Saves image locally
  /// - Tries to upload to Supabase Storage (best effort)
  /// - Returns LOCAL path always (UI-safe)
  static Future<String?> pickAndSaveImage({
    required String childLocalId,
    required String? childCloudId,
    required int year,
  }) async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (picked == null) return null;

    // ---------------------------------------------------------------------
    // 1️⃣ Save locally
    // ---------------------------------------------------------------------
    final Directory appDir = await getApplicationDocumentsDirectory();

    final Directory targetDir = Directory(
      p.join(
        appDir.path,
        'seeme_grow',
        childLocalId,
        'year_$year',
      ),
    );

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final String fileName = '$year.jpg';

    final File localImage = await File(picked.path).copy(
      p.join(targetDir.path, fileName),
    );

    // ---------------------------------------------------------------------
    // 2️⃣ Upload to Supabase (ONLY if possible)
    // ---------------------------------------------------------------------
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        debugPrint('⏭️ Skip upload: user not authenticated');
        return localImage.path;
      }

      if (childCloudId == null) {
        debugPrint('⏭️ Skip upload: child not synced yet');
        return localImage.path;
      }

      final String storagePath =
          '${user.id}/$childCloudId/year_$year.jpg';

      await _supabase.storage.from('SeeMeGrow').upload(
            storagePath,
            localImage,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      debugPrint('☁️ Image uploaded: $storagePath');
    } catch (e) {
      // ⚠️ Never break UX
      debugPrint('❌ Image upload failed: $e');
    }

    // ---------------------------------------------------------------------
    // 3️⃣ Always return local path
    // ---------------------------------------------------------------------
    return localImage.path;
  }
}
