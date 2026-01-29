enum SyncState {
  pending,
  synced,
  failed,
}

class YearPhoto {
  /// Year of the photo (e.g. age)
  final int year;

  /// Local file path OR cloud URL later
  final String imagePath;

  /// 🔄 Sync state (offline → online)
  final SyncState syncState;

  /// 🕒 Last update timestamp
  final DateTime updatedAt;

  YearPhoto({
    required this.year,
    required this.imagePath,
    SyncState? syncState,
    DateTime? updatedAt,
  })  : syncState = syncState ?? SyncState.pending,
        updatedAt = updatedAt ?? DateTime.now();

  // ---------------------------------------------------------------------------
  // JSON (Backward + Forward compatible)
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'imagePath': imagePath,
      'syncState': syncState.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory YearPhoto.fromJson(Map<String, dynamic> json) {
    return YearPhoto(
      year: json['year'],
      imagePath: json['imagePath'],

      syncState: SyncState.values.firstWhere(
        (e) => e.name == json['syncState'],
        orElse: () => SyncState.pending, // backward compatibility
      ),

      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool get isSynced => syncState == SyncState.synced;

  bool get needsSync => syncState != SyncState.synced;

  YearPhoto copyWith({
    int? year,
    String? imagePath,
    SyncState? syncState,
    DateTime? updatedAt,
  }) {
    return YearPhoto(
      year: year ?? this.year,
      imagePath: imagePath ?? this.imagePath,
      syncState: syncState ?? this.syncState,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
