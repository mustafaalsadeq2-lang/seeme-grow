import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:seeme_grow_clean/l10n/app_localizations.dart';

import '../models/child.dart';
import '../storage/local_storage_service.dart';
import '../utils/app_tokens.dart';

// Dark immersive background colour.
const _kViewerBg = Color(0xFF0E1410);

class YearDetailScreen extends StatefulWidget {
  final Child child;
  final int year;

  const YearDetailScreen({
    super.key,
    required this.child,
    required this.year,
  });

  @override
  State<YearDetailScreen> createState() => _YearDetailScreenState();
}

class _YearDetailScreenState extends State<YearDetailScreen>
    with SingleTickerProviderStateMixin {
  String? _imagePath;
  bool _loading = false;
  // Freshly loaded child — used for the 19-segment progress bar.
  Child? _freshChild;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  final ImagePicker _picker = ImagePicker();

  // Blocked video extensions.
  static const _blockedExtensions = {
    'mp4', 'mov', 'avi', 'mkv', 'm4v', '3gp', 'webm', 'flv', 'wmv',
  };

  // Year names spelled out for the serif heading.
  static const _yearNames = [
    'Birth',
    'Year One',   'Year Two',       'Year Three',    'Year Four',
    'Year Five',  'Year Six',       'Year Seven',    'Year Eight',
    'Year Nine',  'Year Ten',       'Year Eleven',   'Year Twelve',
    'Year Thirteen', 'Year Fourteen', 'Year Fifteen', 'Year Sixteen',
    'Year Seventeen', 'Year Eighteen',
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _loadFromStorage();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> _loadFromStorage() async {
    final children = await LocalStorageService.loadChildren();
    final fresh    = children.firstWhere(
      (c) => c.localId == widget.child.localId,
    );
    if (!mounted) return;
    setState(() {
      _freshChild = fresh;
      _imagePath  = fresh.yearPhotos[widget.year];
    });
    _fadeController.forward(from: 0);
  }

  int get _completedCount {
    final child = _freshChild ?? widget.child;
    return child.yearPhotos.values.where((p) => p.trim().isNotEmpty).length;
  }

  bool _hasPhotoForYear(int year) {
    final child = _freshChild ?? widget.child;
    final path  = child.yearPhotos[year];
    return path != null && path.trim().isNotEmpty;
  }

  // ── Photo picking ──────────────────────────────────────────────────────────

  Future<void> _showPhotoOptions() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoSourceSheet(),
    );
    if (source == null) return;
    await _pickPhoto(source);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (picked == null) return;

      // Block video files.
      final ext = picked.path.split('.').last.toLowerCase();
      if (_blockedExtensions.contains(ext)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.videoNotAllowed),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() => _loading = true);

      final appDir  = await getApplicationDocumentsDirectory();
      final childDir= Directory('${appDir.path}/${widget.child.localId}');
      if (!await childDir.exists()) await childDir.create(recursive: true);

      final ts      = DateTime.now().millisecondsSinceEpoch;
      final newPath = '${childDir.path}/year_${widget.year}_$ts.jpg';
      await File(picked.path).copy(newPath);

      final children = await LocalStorageService.loadChildren();
      final idx      = children.indexWhere((c) => c.localId == widget.child.localId);
      children[idx].yearPhotos[widget.year] = newPath;
      await LocalStorageService.saveChildren(children);

      HapticFeedback.mediumImpact();
      await _loadFromStorage();

      if (!mounted) return;
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✨ Memory saved', textAlign: TextAlign.center),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save photo: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Year navigation ────────────────────────────────────────────────────────

  void _goToYear(int year) {
    if (year < 0 || year > 18) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, s) => YearDetailScreen(
          child: _freshChild ?? widget.child,
          year: year,
        ),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, a, s, child) {
          final dir = year > widget.year ? 1.0 : -1.0;
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(dir * 0.3, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: FadeTransition(
              opacity: CurvedAnimation(parent: a, curve: Curves.easeIn),
              child: child,
            ),
          );
        },
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get _yearHeading {
    final idx = widget.year.clamp(0, _yearNames.length - 1);
    return '${_yearNames[idx]}.';
  }

  String _calYear() =>
      '${widget.child.birthDate.year + widget.year}';

  // ── UI ─────────────────────────────────────────────────────────────────────

  Widget _buildProgressSegments() {
    return Row(
      children: List.generate(19, (i) {
        final filled = _hasPhotoForYear(i);
        final isCurrent = i == widget.year;
        return Expanded(
          child: Container(
            height: isCurrent ? 4 : 3,
            margin: EdgeInsets.only(right: i < 18 ? 3 : 0),
            decoration: BoxDecoration(
              color: filled
                  ? T.forest
                  : isCurrent
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPhotoOrPlaceholder() {
    if (_imagePath == null || _imagePath!.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _showPhotoOptions,
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                color: Colors.white70,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap to add a photo',
            style: serif(fontSize: 16, color: Colors.white60),
          ),
        ],
      );
    }

    final file = File(_imagePath!);
    if (!file.existsSync()) {
      return const Center(
        child: Text('Image not found', style: TextStyle(color: Colors.redAccent)),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Image.file(file, fit: BoxFit.contain),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: _kViewerBg,
      body: Stack(
        children: [
          // ── Photo (fills the middle area) ──────────────────────────────────
          Positioned.fill(
            child: Center(child: _buildPhotoOrPlaceholder()),
          ),

          // ── Top overlay ────────────────────────────────────────────────────
          Positioned(
            top: padding.top + 12,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress segments
                _buildProgressSegments(),
                const SizedBox(height: 16),

                // Close | heading | edit
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _GlassButton(
                      icon: Icons.close,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _yearHeading,
                        style: serif(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          italic: true,
                          color: Colors.white,
                          height: 1.0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _GlassButton(
                      icon: _imagePath != null && _imagePath!.isNotEmpty
                          ? Icons.edit_outlined
                          : Icons.add_a_photo_outlined,
                      onTap: _loading ? null : _showPhotoOptions,
                    ),
                    const SizedBox(width: 8),
                    _GlassButton(
                      icon: Icons.tag,
                      label: '$_completedCount/19',
                      onTap: null,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Bottom overlay ─────────────────────────────────────────────────
          Positioned(
            bottom: padding.bottom + 24,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Calendar year
                Text(
                  _calYear(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white38,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 16),

                // Prev / next year navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _YearNavButton(
                      isPrevious: true,
                      onTap: widget.year > 0
                          ? () => _goToYear(widget.year - 1)
                          : null,
                    ),
                    const SizedBox(width: 24),
                    Text(
                      widget.year == 0 ? 'Birth' : 'Year ${widget.year}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 24),
                    _YearNavButton(
                      isPrevious: false,
                      onTap: widget.year < 18
                          ? () => _goToYear(widget.year + 1)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Loading overlay ────────────────────────────────────────────────
          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Photo source bottom sheet ──────────────────────────────────────────────

class _PhotoSourceSheet extends StatelessWidget {
  const _PhotoSourceSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E1B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _SheetTile(
              icon: Icons.camera_alt_outlined,
              label: 'Take Photo',
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const Divider(height: 1, color: Colors.white10),
            _SheetTile(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const Divider(height: 1, color: Colors.white10),
            _SheetTile(
              icon: Icons.close,
              label: 'Cancel',
              color: Colors.white38,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _SheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}

// ── Glass button ───────────────────────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? label;

  const _GlassButton({
    required this.icon,
    this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label != null ? 12 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: onTap != null ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ),
        child: label != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white70, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    label!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Icon(
                icon,
                color: onTap != null ? Colors.white : Colors.white38,
                size: 20,
              ),
      ),
    );
  }
}

// ── Year navigation button ─────────────────────────────────────────────────

class _YearNavButton extends StatelessWidget {
  final bool isPrevious;
  final VoidCallback? onTap;

  const _YearNavButton({
    required this.isPrevious,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: active ? 0.12 : 0.05),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: active ? 0.25 : 0.1),
          ),
        ),
        child: Icon(
          isPrevious ? Icons.chevron_left : Icons.chevron_right,
          color: active ? Colors.white : Colors.white24,
          size: 24,
        ),
      ),
    );
  }
}
