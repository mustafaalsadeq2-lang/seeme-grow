import '../models/child.dart';
import '../services/image_file_service.dart';
import 'photo_repository.dart';

class LocalPhotoRepository implements PhotoRepository {
  @override
  Future<String?> addPhoto({
    required Child child,
    required int age,
  }) {
    // 🔒 Safety: if child not synced yet → local only
    if (child.cloudId == null) {
      return ImageFileService.pickAndSaveImageLocalOnly(
        childLocalId: child.localId,
        year: age,
      );
    }

    // ☁️ Local + Cloud
    return ImageFileService.pickAndSaveImage(
      childLocalId: child.localId,
      childCloudId: child.cloudId!,
      year: age,
    );
  }

  @override
  Future<bool> hasPhotos(String childId) async {
    // UI already knows via child.yearPhotos
    return true;
  }

  @override
  Future<String?> getCoverPhoto(String childId) async {
    return null;
  }
}
