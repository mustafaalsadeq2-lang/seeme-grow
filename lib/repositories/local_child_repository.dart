import '../models/child.dart';
import '../storage/local_storage_service.dart';
import 'child_repository.dart';

class LocalChildRepository implements ChildRepository {
  @override
  Future<List<Child>> getAll() {
    return LocalStorageService.loadChildren();
  }

  @override
  Future<void> create(Child child) {
    final pendingChild = child.copyWith(
      syncState: SyncState.pending,
      updatedAt: DateTime.now(),
    );

    return LocalStorageService.addChild(pendingChild);
  }

  @override
  Future<void> update(Child child) {
    final pendingChild = child.copyWith(
      syncState: SyncState.pending,
      updatedAt: DateTime.now(),
    );

    return LocalStorageService.updateChild(pendingChild);
  }

  @override
  Future<void> delete(String localId) {
    // Local delete only for now
    // Cloud delete will be handled in Sync phase
    return LocalStorageService.deleteChild(localId);
  }

  // ---------------------------------------------------------------------------
  // Sync helpers (B3 foundation)
  // ---------------------------------------------------------------------------

  /// Returns children that need sync (pending or failed)
  Future<List<Child>> getPendingSync() async {
    final all = await getAll();
    return all.where((c) => c.needsSync).toList();
  }

  /// Mark child as successfully synced
  Future<void> markAsSynced({
    required String localId,
    required String cloudId,
    required String userId,
  }) async {
    final children = await getAll();

    final index = children.indexWhere((c) => c.localId == localId);
    if (index == -1) return;

    final syncedChild = children[index].copyWith(
      cloudId: cloudId,
      userId: userId,
      syncState: SyncState.synced,
      updatedAt: DateTime.now(),
    );

    children[index] = syncedChild;
    await LocalStorageService.saveChildren(children);
  }

  /// Mark sync failure (will retry later)
  Future<void> markAsFailed(String localId) async {
    final children = await getAll();

    final index = children.indexWhere((c) => c.localId == localId);
    if (index == -1) return;

    final failedChild = children[index].copyWith(
      syncState: SyncState.failed,
      updatedAt: DateTime.now(),
    );

    children[index] = failedChild;
    await LocalStorageService.saveChildren(children);
  }
}
