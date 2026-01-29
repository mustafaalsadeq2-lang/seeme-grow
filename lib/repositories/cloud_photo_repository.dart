import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/photo_repository.dart';
import '../services/image_file_service.dart';

class CloudPhotoRepository implements PhotoRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<String?> addPhoto({
    required String childId, // local id
    required int age,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    // 1️⃣ get child cloud id
    final childRes = await _supabase
        .from('children')
        .select('id')
        .eq('local_id', childId)
        .single();

    final String childCloudId = childRes['id'];

    // 2️⃣ save image (local + storage)
    final localPath = await ImageFileService.pickAndSaveImage(
      childLocalId: childId,
      childCloudId: childCloudId,
      year: age,
    );

    if (localPath == null) return null;

    // 3️⃣ insert DB row
    await _supabase.from('year_photos').upsert({
      'child_id': childCloudId,
      'year': age,
      'image_path': localPath,
    });

    return localPath;
  }

  @override
  Future<bool> hasPhotos(String childId) async => true;

  @override
  Future<String?> getCoverPhoto(String childId) async => null;
}
