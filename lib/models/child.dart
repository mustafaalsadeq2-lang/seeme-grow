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

    return Child(
      // 🔁 Backward compatibility:
      // older data used `id`
      localId: (json['localId'] ?? json['id']) as String,

      cloudId: json['cloudId'] as String?,
      userId: json['userId'] as String?,

      name: json['name'] as String,
      birthDate: DateTime.parse(json['birthDate']),

      yearPhotos: parsedYearPhotos,

      // 🔄 Sync fields (safe defaults for old data)
      syncState: SyncState.values.firstWhere(
        (e) => e.name == json['syncState'],
        orElse: () =>
            (json['cloudId'] != null ? SyncState.synced : SyncState.pending),
      ),

      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
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
