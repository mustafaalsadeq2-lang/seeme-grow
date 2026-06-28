import 'dart:io';

import 'package:exif/exif.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:seeme_grow_clean/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/child.dart';
import '../storage/local_storage_service.dart';
import '../utils/app_tokens.dart';
import 'comparison_screen.dart';
import 'timeline_movie_screen.dart';
import 'voice_note_screen.dart';
import 'year_detail_screen.dart';

class TimelineScreen extends StatefulWidget {
  final String childId;

  const TimelineScreen({
    super.key,
    required this.childId,
  });

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen>
    with TickerProviderStateMixin {
  Child? _child;
  bool _loading   = true;
  bool _importing = false;
  int _lastCompletedYears = 0;

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AnimationController _shimmerController;
  late AnimationController _listController;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _loadChild(initial: true);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _shimmerController.dispose();
    _listController.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadChild({bool initial = false}) async {
    final children = await LocalStorageService.loadChildren();
    final child    = children.firstWhere((c) => c.localId == widget.childId);

    if (!mounted) return;

    final completedNow = child.yearPhotos.values
        .where((p) => p.trim().isNotEmpty)
        .length;

    if (!initial && completedNow > _lastCompletedYears) {
      _celebrate(previous: _lastCompletedYears, current: completedNow);
    }

    setState(() {
      _child              = child;
      _loading            = false;
      _lastCompletedYears = completedNow;
    });

    _progressController.forward(from: 0);
    _listController.forward(from: 0);
  }

  int get _currentYear {
    final birth = _child!.birthDate;
    final now   = DateTime.now();
    int age     = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age.clamp(0, 18);
  }

  bool _hasPhoto(int year) {
    final path = _child?.yearPhotos[year];
    return path != null && path.trim().isNotEmpty && File(path).existsSync();
  }

  int get _completedYears => _lastCompletedYears;

  // ── Smart Import ──────────────────────────────────────────────────────────

  Future<void> _importPhotos() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty || !mounted) return;

    setState(() => _importing = true);

    final child     = _child!;
    final birthDate = child.birthDate;

    // Group candidates: year → [(XFile, photoDate)]
    final Map<int, List<(XFile, DateTime)>> candidates = {};
    int skipped = 0;

    for (final xfile in picked) {
      // Read EXIF from file bytes.
      final bytes = await File(xfile.path).readAsBytes();
      final tags  = await readExifFromBytes(bytes);

      // Prefer DateTimeOriginal; fall back to Image DateTime.
      final rawTag = tags['EXIF DateTimeOriginal'] ?? tags['Image DateTime'];
      if (rawTag == null) { skipped++; continue; }

      // Parse "YYYY:MM:DD HH:MM:SS".
      DateTime? photoDate;
      try {
        final s = rawTag.printable.trim().split(RegExp(r'[: ]'));
        if (s.length >= 3) {
          photoDate = DateTime(
            int.parse(s[0]), int.parse(s[1]), int.parse(s[2]),
            s.length > 3 ? int.tryParse(s[3]) ?? 0 : 0,
            s.length > 4 ? int.tryParse(s[4]) ?? 0 : 0,
            s.length > 5 ? int.tryParse(s[5]) ?? 0 : 0,
          );
        }
      } catch (_) { /* parse failed */ }

      if (photoDate == null || photoDate.isBefore(birthDate)) {
        skipped++;
        continue;
      }

      final year = (photoDate.difference(birthDate).inDays / 365.25).floor();
      if (year < 0 || year > 18) { skipped++; continue; }

      candidates.putIfAbsent(year, () => []).add((xfile, photoDate));
    }

    // Write winners to disk.
    int imported = 0;

    if (candidates.isNotEmpty) {
      final children = await LocalStorageService.loadChildren();
      final idx      = children.indexWhere((c) => c.localId == child.localId);

      if (idx != -1) {
        final appDir   = await getApplicationDocumentsDirectory();
        final childDir = Directory('${appDir.path}/${child.localId}');
        if (!await childDir.exists()) await childDir.create(recursive: true);

        // Resolve cloud child ID once before the loop.
        final supabase = Supabase.instance.client;
        final user     = supabase.auth.currentUser;
        String? cloudChildId;
        if (user != null) {
          try {
            final row = await supabase
                .from('children')
                .select('id')
                .eq('user_id', user.id)
                .eq('local_id', child.localId)
                .maybeSingle();
            cloudChildId = row?['id'] as String?;
          } catch (e) {
            debugPrint('⚠️ Smart Import: cloud child lookup failed: $e');
          }
        }

        for (final entry in candidates.entries) {
          final year = entry.key;
          final list = entry.value;

          // Skip years that already have a valid photo.
          if (_hasPhoto(year)) { skipped += list.length; continue; }

          // Take the earliest photo in this year.
          list.sort((a, b) => a.$2.compareTo(b.$2));
          skipped += list.length - 1; // extras discarded

          final ts      = DateTime.now().millisecondsSinceEpoch;
          final newPath = '${childDir.path}/year_${year}_$ts.jpg';
          try {
            await File(list.first.$1.path).copy(newPath);
            children[idx].yearPhotos[year] = newPath;
            imported++;

            // Cloud upload — best-effort, never breaks local import.
            if (user != null && cloudChildId != null) {
              try {
                final storagePath =
                    '${user.id}/$cloudChildId/year_$year.jpg';
                await supabase.storage
                    .from('SeeMeGrow')
                    .upload(
                      storagePath,
                      File(newPath),
                      fileOptions: const FileOptions(
                        upsert: true,
                        contentType: 'image/jpeg',
                      ),
                    );
                await supabase.from('year_photos').upsert(
                  {
                    'child_id'  : cloudChildId,
                    'user_id'   : user.id,
                    'year'      : year,
                    'image_path': storagePath,
                    'sync_state': 'synced',
                  },
                  onConflict: 'child_id,year',
                );
                debugPrint('☁️ Smart Import: year $year uploaded');
              } catch (e) {
                debugPrint(
                    '⚠️ Smart Import: cloud upload failed year=$year: $e');
              }
            }
          } catch (_) {
            skipped++;
          }
        }

        if (imported > 0) await LocalStorageService.saveChildren(children);
      }
    }

    if (!mounted) return;
    setState(() => _importing = false);
    await _loadChild();

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.importCompleteTitle),
        content: Text(l10n.importResult(imported, skipped)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  // ── Celebrate ─────────────────────────────────────────────────────────────

  void _celebrate({required int previous, required int current}) {
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context)!;
    final String message;
    if (current == 1) {
      message = l10n.firstMemorySaved;
    } else if (current == 19) {
      message = l10n.allMemoriesComplete;
    } else if (current == _currentYear + 1) {
      message = l10n.yearCompleted(_currentYear);
    } else {
      message = l10n.memorySavedSnack;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ));
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, a, s) => page,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (_, animation, s, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Consolidates tap logic for any year tile.
  Future<void> _openYear(int year) async {
    final child    = _child!;
    final hasPhoto = _hasPhoto(year);

    if (hasPhoto) {
      final result = await _openStoriesViewer(year);
      if (result == 'edit' && mounted) {
        await Navigator.push(
          context,
          _createRoute(YearDetailScreen(child: child, year: year)),
        );
      }
    } else {
      await Navigator.push(
        context,
        _createRoute(YearDetailScreen(child: child, year: year)),
      );
    }
    if (mounted) _loadChild();
  }

  // ── Stories viewer ────────────────────────────────────────────────────────

  List<(int, String)> get _photosWithYears {
    final child = _child;
    if (child == null) return [];
    final result = <(int, String)>[];
    for (int y = 0; y <= 18; y++) {
      final path = child.yearPhotos[y];
      if (path != null && path.trim().isNotEmpty) result.add((y, path));
    }
    return result;
  }

  Future<String?> _openStoriesViewer(int tappedYear) async {
    final photos = _photosWithYears;
    if (photos.isEmpty) return null;
    final startIndex = photos.indexWhere((p) => p.$1 == tappedYear);
    if (startIndex == -1) return null;
    final child = _child!;
    return Navigator.push<String>(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, a, s) => _StoriesPhotoViewer(
          photos: photos,
          initialIndex: startIndex,
          childName: child.name,
          birthYear: child.birthDate.year,
          childId: widget.childId,
        ),
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (_, animation, s, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  // ── Shimmer skeleton ──────────────────────────────────────────────────────

  Widget _buildShimmerSkeleton() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade100,
            Colors.grey.shade300,
          ],
          stops: const [0.0, 0.5, 1.0],
          transform: _SlidingGradientTransform(_shimmerController.value),
        ).createShader(bounds),
        child: child!,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        itemBuilder: (_, index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 88,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100, height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 150, height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Progress header ───────────────────────────────────────────────────────

  Widget _buildProgressHeader() {
    final completed = _completedYears;
    final percent   = (completed / 19 * 100).round();
    final l10n      = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.nOfNineteen(completed),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: T.ink,
                ),
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: T.forest,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (_, snapshot) {
              final target = completed / 19;
              return Container(
                height: 6,
                decoration: BoxDecoration(
                  color: T.hairline,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FractionallySizedBox(
                    widthFactor: (target * _progressAnimation.value)
                        .clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: T.forest,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Birth hero (230px) ────────────────────────────────────────────────────

  Widget _buildBirthHero() {
    final child    = _child!;
    final hasPhoto = _hasPhoto(0);
    final imagePath= child.yearPhotos[0];

    return GestureDetector(
      onTap: () => _openYear(0),
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: T.cream,
        ),
        clipBehavior: Clip.antiAlias,
        child: hasPhoto
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(imagePath!), fit: BoxFit.cover, cacheWidth: 600),
                  // Gradient overlay
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xAA000000)],
                        stops: [0.4, 1.0],
                      ),
                    ),
                  ),
                  // Birth label
                  Positioned.directional(
                    textDirection: Directionality.of(context),
                    bottom: 20,
                    start: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.birth,
                          style: serif(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${child.birthDate.year}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // "Captured" chip
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(
                              color: T.forest,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            AppLocalizations.of(context)!.capturedLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _openYear(0),
                    child: Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: T.forest.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: T.forest,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.addBirthPhoto,
                    style: serif(
                      fontSize: 15,
                      color: T.ink3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${child.name} · ${child.birthDate.year}',
                    style: const TextStyle(fontSize: 12, color: T.ink4),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Year card (88px horizontal row) ──────────────────────────────────────

  Widget _buildYearCard(int year) {
    final child       = _child!;
    final hasPhoto    = _hasPhoto(year);
    final isFuture    = year > _currentYear;
    final isCurrent   = year == _currentYear;
    final imagePath   = child.yearPhotos[year];
    final calYear     = child.birthDate.year + year;

    return GestureDetector(
      onTap: isFuture ? null : () => _openYear(year),
      child: Container(
        height: 88,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: T.hairline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left: year info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.yearN(year),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isFuture ? T.ink4 : T.ink,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: T.forest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.nowLabel,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$calYear',
                      style: TextStyle(
                        fontSize: 12,
                        color: isFuture ? T.ink4 : T.ink3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hasPhoto)
                      Row(
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(
                              color: T.forest,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.capturedLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: T.forest,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    else if (isFuture)
                      Text(
                        AppLocalizations.of(context)!.waitingLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: T.ink4,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      Text(
                        AppLocalizations.of(context)!.tapToAdd,
                        style: const TextStyle(
                          fontSize: 12,
                          color: T.ink3,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // End: photo thumbnail
            ClipRRect(
              borderRadius: BorderRadiusDirectional.only(
                topEnd: const Radius.circular(16),
                bottomEnd: const Radius.circular(16),
              ).resolve(Directionality.of(context)),
              child: SizedBox(
                width: 88,
                height: 88,
                child: hasPhoto
                    ? Image.file(
                        File(imagePath!),
                        fit: BoxFit.cover,
                        cacheWidth: 180,
                      )
                    : Container(
                        color: isFuture
                            ? const Color(0xFFF5F5F5)
                            : T.cream,
                        child: Icon(
                          isFuture
                              ? Icons.lock_outline
                              : Icons.add_photo_alternate_outlined,
                          size: 22,
                          color: isFuture ? T.ink4 : T.ink3,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 20, 0, 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: T.ink3,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ── Import nudge ──────────────────────────────────────────────────────────

  Widget _buildImportNudge() {
    return GestureDetector(
      onTap: _importing ? null : _importPhotos,
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: T.forestSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: T.forest.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            if (_importing)
              const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2, color: T.forest,
                ),
              )
            else
              const Icon(Icons.photo_library_outlined, color: T.forest, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _importing
                    ? AppLocalizations.of(context)!.importingPhotos
                    : AppLocalizations.of(context)!.importNudgeText,
                style: const TextStyle(fontSize: 13, color: T.forest),
              ),
            ),
            if (!_importing)
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
                color: T.forest,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  // ── Animation helper ──────────────────────────────────────────────────────

  Animation<double> _itemAnimation(int index) {
    final start = (index * 0.04).clamp(0.0, 0.6);
    final end   = (start + 0.4).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _listController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  Widget _animatedItem(int index, Widget child) {
    final anim = _itemAnimation(index);
    return AnimatedBuilder(
      animation: anim,
      builder: (context, ch) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - anim.value)),
          child: ch,
        ),
      ),
      child: child,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading || _child == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.timelineTitle)),
        body: _buildShimmerSkeleton(),
      );
    }

    final child = _child!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          child.name,
          style: serif(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          // Stats screen removed from timeline as per redesign.
          if (_completedYears >= 2)
            IconButton(
              icon: const Icon(Icons.compare_arrows),
              tooltip: 'Compare Growth',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ComparisonScreen(
                      childId: widget.childId,
                      childName: child.name,
                    ),
                  ),
                );
              },
            ),
          if (_completedYears > 0)
            IconButton(
              icon: const Icon(Icons.play_circle_fill),
              tooltip: 'Play Timeline',
              onPressed: () async {
                await Navigator.push(
                  context,
                  _createRoute(TimelineMovieScreen(child: child)),
                );
              },
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Progress header
          SliverToBoxAdapter(child: _buildProgressHeader()),

          // Birth hero
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _animatedItem(0, _buildBirthHero()),
            ),
          ),

          if (_completedYears < 18)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildImportNudge(),
              ),
            ),

          // Section label
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSectionLabel(AppLocalizations.of(context)!.theJourney),
            ),
          ),

          // Year cards 1–18
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final year = i + 1;
                  return _animatedItem(year, _buildYearCard(year));
                },
                childCount: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fullscreen photo zoom viewer
// ---------------------------------------------------------------------------
class _PhotoZoomScreen extends StatefulWidget {
  final String imagePath;
  final String heroTag;
  final String title;
  final String childId;
  final String childName;
  final int year;

  const _PhotoZoomScreen({
    required this.imagePath,
    required this.heroTag,
    required this.title,
    required this.childId,
    required this.childName,
    required this.year,
  });

  @override
  State<_PhotoZoomScreen> createState() => _PhotoZoomScreenState();
}

class _PhotoZoomScreenState extends State<_PhotoZoomScreen>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformController = TransformationController();
  late AnimationController _animController;
  Animation<Matrix4>? _matrixAnimation;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        if (_matrixAnimation != null) {
          _transformController.value = _matrixAnimation!.value;
        }
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    final Matrix4 target;
    if (currentScale > 1.5) {
      target = Matrix4.identity();
    } else {
      const scale = 3.0;
      final pos = _doubleTapDetails!.localPosition;
      target = Matrix4.identity()
        ..translateByDouble(-pos.dx * (scale - 1), -pos.dy * (scale - 1), 0.0, 0.0)
        ..scaleByDouble(scale, scale, 1.0, 1.0);
    }
    _matrixAnimation = Matrix4Tween(
      begin: _transformController.value,
      end: target,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onDoubleTapDown: (d) => _doubleTapDetails = d,
              onDoubleTap: _handleDoubleTap,
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 1.0,
                maxScale: 5.0,
                child: Center(
                  child: Hero(
                    tag: widget.heroTag,
                    child: Image.file(File(widget.imagePath), fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: padding.top + 12, left: 12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(
                  color: Colors.black45, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 22),
              ),
            ),
          ),
          Positioned(
            top: padding.top + 12, right: 60,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VoiceNoteScreen(
                    childId: widget.childId,
                    childName: widget.childName,
                    year: widget.year,
                  ),
                ),
              ),
              child: Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(
                  color: Colors.black45, shape: BoxShape.circle),
                child: const Icon(Icons.mic_outlined, color: Colors.white, size: 20),
              ),
            ),
          ),
          Positioned(
            top: padding.top + 12, right: 12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context, 'edit'),
              child: Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(
                  color: Colors.black45, shape: BoxShape.circle),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
          ),
          Positioned(
            bottom: padding.bottom + 28, left: 24, right: 24,
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Snapchat-style Stories Photo Viewer
// ---------------------------------------------------------------------------
class _StoriesPhotoViewer extends StatefulWidget {
  final List<(int, String)> photos;
  final int initialIndex;
  final String childName;
  final int birthYear;
  final String childId;

  const _StoriesPhotoViewer({
    required this.photos,
    required this.initialIndex,
    required this.childName,
    required this.birthYear,
    required this.childId,
  });

  @override
  State<_StoriesPhotoViewer> createState() => _StoriesPhotoViewerState();
}

class _StoriesPhotoViewerState extends State<_StoriesPhotoViewer>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  double _dragOffset = 0;
  bool _isDragging  = false;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String _getYearLabel(int year) {
    final l10n = AppLocalizations.of(context)!;
    final gregorian = widget.birthYear + year;
    return year == 0
        ? '${l10n.birth} • $gregorian'
        : '${l10n.yearN(year)} • $gregorian';
  }

  void _onVerticalDragUpdate(DragUpdateDetails d) {
    setState(() {
      _isDragging = true;
      _dragOffset += d.delta.dy;
    });
  }

  void _onVerticalDragEnd(DragEndDetails d) {
    final velocity = d.primaryVelocity ?? 0;
    if (_dragOffset > 100 || velocity > 500) {
      _fadeController.reverse().then((_) {
        if (mounted) Navigator.pop(context);
      });
    } else {
      setState(() { _dragOffset = 0; _isDragging = false; });
    }
  }

  void _onPageChanged(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  void _openVoiceNote() {
    final (year, _) = widget.photos[_currentIndex];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoiceNoteScreen(
          childId: widget.childId,
          childName: widget.childName,
          year: year,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding      = MediaQuery.of(context).padding;
    final screenHeight = MediaQuery.of(context).size.height;
    final dragProgress = (_dragOffset.abs() / (screenHeight * 0.3)).clamp(0.0, 1.0);
    final opacity = 1.0 - (dragProgress * 0.5);
    final scale   = 1.0 - (dragProgress * 0.1);

    return FadeTransition(
      opacity: _fadeController,
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: opacity),
        body: GestureDetector(
          onVerticalDragUpdate: _onVerticalDragUpdate,
          onVerticalDragEnd: _onVerticalDragEnd,
          child: Transform.translate(
            offset: Offset(0, _dragOffset.clamp(0, screenHeight * 0.5)),
            child: Transform.scale(
              scale: scale,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: widget.photos.length,
                      itemBuilder: (_, index) {
                        final (_, path) = widget.photos[index];
                        return Center(
                          child: Image.file(
                            File(path),
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        );
                      },
                    ),
                  ),
                  // Progress indicators
                  Positioned(
                    top: padding.top + 12, left: 16, right: 16,
                    child: Row(
                      children: List.generate(widget.photos.length, (index) {
                        final isActive = index == _currentIndex;
                        final isPast   = index < _currentIndex;
                        return Expanded(
                          child: Container(
                            height: 3,
                            margin: EdgeInsets.only(
                              right: index < widget.photos.length - 1 ? 4 : 0),
                            decoration: BoxDecoration(
                              color: isActive || isPast
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  // Close
                  Positioned(
                    top: padding.top + 24, left: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                  // Voice note
                  Positioned(
                    top: padding.top + 24, right: 60,
                    child: GestureDetector(
                      onTap: _openVoiceNote,
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle),
                        child: const Icon(Icons.mic_outlined, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  // Edit
                  Positioned(
                    top: padding.top + 24, right: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, 'edit'),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle),
                        child: const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  // Bottom info
                  Positioned(
                    bottom: padding.bottom + 40, left: 24, right: 24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.childName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white, fontSize: 18,
                            fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _getYearLabel(widget.photos[_currentIndex].$1),
                            key: ValueKey(_currentIndex),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!_isDragging)
                          Text(
                            AppLocalizations.of(context)!.swipeDownToClose,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  // Left/Right tap zones
                  Positioned.fill(
                    top: padding.top + 80,
                    bottom: padding.bottom + 120,
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              if (_currentIndex > 0) {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                );
                              }
                            },
                            child: const SizedBox.expand(),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              if (_currentIndex < widget.photos.length - 1) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                );
                              }
                            },
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gradient transform for shimmer animation
// ---------------------------------------------------------------------------
class _SlidingGradientTransform extends GradientTransform {
  final double percent;
  const _SlidingGradientTransform(this.percent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (2 * percent - 1), 0, 0);
  }
}
