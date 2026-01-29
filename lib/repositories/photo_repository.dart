abstract class PhotoRepository {
  /// Returns the latest (cover) photo path for a child
  Future<String?> getCoverPhoto(String childId);

  /// Returns true if the child has any photos
  Future<bool> hasPhotos(String childId);

  /// Pick & save photo for a specific age
  Future<String?> addPhoto({
    required String childId,
    required int age,
  });
}
