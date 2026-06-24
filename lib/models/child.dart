enum SyncState {
  pending,
  synced,
  failed,
}

class Child {
  /// 🔹 Local identifier (used offline & UI)
  final String localId;

  /// 🔹 Cloud identifier (Supabase row id)
  /// null = not synced yet
  final String? cloudId;

  /// 🔹 Owner user id (Supabase auth user id)
  final String? userId;

  final String name;
  final DateTime birthDate;

  /// key = year, value = local image path
  final Map<int, String> yearPhotos;

  /// 🔄 Sync state (offline → online)
  final SyncState syncState;

  /// 🕒 Last local update (used for conflict resolution)
  final DateTime updatedAt;

  Child({
    required this.localId,
    required this.name,
    required this.birthDate,
    this.cloudId,
    this.userId,
    Map<int, String>? yearPhotos,
    SyncState? syncState,
    DateTime? updatedAt,
  })  : yearPhotos = yearPhotos ?? {},
        syncState = syncState ?? SyncState.pending,
        updatedAt = updatedAt ?? DateTime.now();

  // ---------------------------------------------------------------------------
  // Backward + Forward compatible JSON
  // ---------------------------------------------------------------------------

  factory Child.fromJson(Map<String, dynamic> json) {
    final rawYearPhotos = json['yearPhotos'];

    Map<int, String> parsedYearPhotos = {};

    if (rawYearPhotos is Map) {
      rawYearPhotos.forEach((key, value) {
        final year = int.tryParse(key.toString());
        if (year != null && value is String) {
          parsedYearPhotos[year] = value;
        }
      });
    }

    // Supabase rows use snake_case; local storage uses camelCase.
    // 'local_id' is only present in Supabase responses.
    final isCloudRow = json.containsKey('local_id');

    return Child(
      // Supabase: local_id | local storage: localId | legacy: id
      localId: (json['local_id'] ?? json['localId'] ?? json['id']) as String,

      // Supabase 'id' is the cloud primary key; local storage has 'cloudId'
      cloudId: isCloudRow
          ? json['id'] as String?
          : json['cloudId'] as String?,

      // Supabase: user_id | local storage: userId
      userId: (json['user_id'] ?? json['userId']) as String?,

      name: json['name'] as String,

      // Supabase: birth_date | local storage: birthDate
      birthDate: DateTime.parse(
        (json['birth_date'] ?? json['birthDate']) as String,
      ),

      yearPhotos: parsedYearPhotos,

      // Supabase: sync_state | local storage: syncState
      syncState: SyncState.values.firstWhere(
        (e) => e.name == (json['sync_state'] ?? json['syncState']),
        orElse: () => isCloudRow
            ? SyncState.synced
            : (json['cloudId'] != null ? SyncState.synced : SyncState.pending),
      ),

      // Supabase: updated_at / created_at | local storage: updatedAt
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : json['created_at'] != null
                  ? DateTime.parse(json['created_at'] as String)
                  : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 🔹 keep both for safety during migration
      'localId': localId,
      'id': localId,

      'cloudId': cloudId,
      'userId': userId,

      'name': name,
      'birthDate': birthDate.toIso8601String(),

      'yearPhotos': yearPhotos.map(
        (key, value) => MapEntry(key.toString(), value),
      ),

      // 🔄 Sync metadata
      'syncState': syncState.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool get isSynced => syncState == SyncState.synced;

  bool get needsSync => syncState != SyncState.synced;

  Child copyWith({
    String? localId,
    String? cloudId,
    String? userId,
    String? name,
    DateTime? birthDate,
    Map<int, String>? yearPhotos,
    SyncState? syncState,
    DateTime? updatedAt,
  }) {
    return Child(
      localId: localId ?? this.localId,
      cloudId: cloudId ?? this.cloudId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      yearPhotos: yearPhotos ?? this.yearPhotos,
      syncState: syncState ?? this.syncState,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
