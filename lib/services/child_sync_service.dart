import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/child.dart';
import '../repositories/local_child_repository.dart';
import 'auth_service.dart';

class ChildSyncService {
  ChildSyncService({
    required SupabaseClient supabase,
    required AuthService authService,
  })  : _supabase = supabase,
        _authService = authService;

  final SupabaseClient _supabase;
  final AuthService _authService;

  final LocalChildRepository _localRepo = LocalChildRepository();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Sync all pending / failed children to Supabase
  /// Cloud sync is best-effort and must NEVER break UX
  Future<void> syncPendingChildren() async {
    debugPrint('🚀 ChildSyncService.syncPendingChildren CALLED');
    debugPrint('👤 currentUser = ${_authService.currentUser}');

    final user = _authService.currentUser;

    if (user == null) {
      debugPrint('⏭️ Child sync skipped: user not logged in');
      return;
    }

    final pendingChildren = await _localRepo.getPendingSync();

    if (pendingChildren.isEmpty) {
      debugPrint('✅ No pending children to sync');
      return;
    }

    debugPrint('🔄 Syncing ${pendingChildren.length} children…');

    for (final child in pendingChildren) {
      await _syncSingleChild(
        child: child,
        userId: user.id,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  Future<void> _syncSingleChild({
    required Child child,
    required String userId,
  }) async {
    try {
      debugPrint('☁️ Uploading child: ${child.name}');

      final response = await _supabase
          .from('children')
          .insert({
            'user_id': userId,
            'local_id': child.localId,
            'name': child.name,
            'birth_date': child.birthDate.toIso8601String(),
          })
          .select('id')
          .single();

      final cloudId = response['id'] as String;

      await _localRepo.markAsSynced(
        localId: child.localId,
        cloudId: cloudId,
        userId: userId,
      );

      debugPrint('✅ Child synced: ${child.name} → $cloudId');
    } catch (e) {
      // IMPORTANT:
      // Cloud errors must never crash the app or block the user
      debugPrint('❌ Child sync failed (${child.name}): $e');
      await _localRepo.markAsFailed(child.localId);
    }
  }
}
