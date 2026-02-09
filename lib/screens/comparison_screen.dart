import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/child.dart';
import '../storage/local_storage_service.dart';

class ComparisonScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const ComparisonScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen>
    with TickerProviderStateMixin {
  Child? _child;
  bool _loading = true;

  late int _leftYear;
  late int _rightYear;
  bool _isExporting = false;

  final GlobalKey _repaintKey = GlobalKey();

  late AnimationController _entryController;
  late Animation<double> _cardEntry;
  late Animation<double> _chipsEntry;
  late Animation<double> _buttonEntry;

  @override
  void initState() {
    super.initState();

    _leftYear = 0;
    _rightYear = 0;

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _cardEntry = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    );

    _chipsEntry = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    );

    _buttonEntry = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    );

    _loadChild();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _loadChild() async {
    final children = await LocalStorageService.loadChildren();
    final match = children.where((c) => c.localId == widget.childId);

    if (!mounted) return;

    if (match.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    final child = match.first;

    debugPrint('DEBUG: childId=${widget.childId}');
    debugPrint('DEBUG: total yearPhotos=${child.yearPhotos.length}');

    // Filter to years that have a real photo file on disk
    final available = <int>[];
    for (final entry in child.yearPhotos.entries) {
      final path = entry.value.trim();
      final exists = path.isNotEmpty && File(path).existsSync();
      debugPrint('DEBUG: year=${entry.key}, path=$path, exists=$exists');
      if (exists) {
        available.add(entry.key);
      }
    }
    available.sort();

    debugPrint('DEBUG: validPhotos (with file on disk)=${available.length}');

    setState(() {
      _child = child;
      _loading = false;
      _leftYear = available.isNotEmpty ? available.first : 0;
      _rightYear = available.length >= 2 ? available.last : _leftYear;
    });

    if (available.length >= 2) {
      _entryController.forward();
    }
  }

  List<int> get _availableYears {
    if (_child == null) return [];
    final years = <int>[];
    for (final entry in _child!.yearPhotos.entries) {
      final path = entry.value.trim();
      if (path.isNotEmpty && File(path).existsSync()) {
        years.add(entry.key);
      }
    }
    years.sort();
    return years;
  }

  String _yearLabel(int year) => year == 0 ? 'Birth' : 'Age $year';

  String _calendarYear(int year) =>
      (_child!.birthDate.year + year).toString();

  bool _yearHasPhoto(int year) {
    final path = _child?.yearPhotos[year];
    if (path == null || path.trim().isEmpty) return false;
    return File(path).existsSync();
  }

  Future<void> _shareComparison() async {
    setState(() => _isExporting = true);

    try {
      final boundary = _repaintKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) throw Exception('Failed to capture image');

      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File(
        '${dir.path}/compare_${widget.childId}_$timestamp.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${widget.childName} – Growth Comparison | SeeMeGrow',
      );

      HapticFeedback.mediumImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Photo builder
  // ---------------------------------------------------------------------------
  Widget _buildPhoto(int year) {
    final path = _child?.yearPhotos[year];

    if (path == null || path.trim().isEmpty) {
      return Container(
        key: ValueKey('empty_$year'),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child:
              Icon(Icons.photo_outlined, color: Colors.white54, size: 48),
        ),
      );
    }

    final file = File(path);
    if (!file.existsSync()) {
      return Container(
        key: ValueKey('missing_$year'),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child:
              Icon(Icons.broken_image, color: Colors.white54, size: 48),
        ),
      );
    }

    return ClipRRect(
      key: ValueKey('photo_$year'),
      borderRadius: BorderRadius.circular(16),
      child: Image.file(
        file,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        cacheWidth: 540,
        errorBuilder: (_, __, ___) => Container(
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Year chip row
  // ---------------------------------------------------------------------------
  Widget _buildChipRow({
    required String label,
    required int selectedYear,
    required ValueChanged<int> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 19,
            itemBuilder: (context, year) {
              final hasPhoto = _yearHasPhoto(year);
              final isSelected = selectedYear == year;
              final chipLabel = year == 0 ? 'Birth' : '$year';

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(chipLabel),
                  selected: isSelected,
                  onSelected: hasPhoto
                      ? (selected) {
                          if (selected) {
                            HapticFeedback.lightImpact();
                            onSelected(year);
                          }
                        }
                      : null,
                  selectedColor: Colors.teal,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : hasPhoto
                            ? null
                            : Colors.grey.shade400,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                  backgroundColor:
                      hasPhoto ? null : Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Loading skeleton
  // ---------------------------------------------------------------------------
  Widget _buildLoadingSkeleton() {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.childName} – Compare')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.childName} – Compare')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.compare_arrows,
                  size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Add at least 2 photos\nto compare growth',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoadingSkeleton();
    if (_availableYears.length < 2) return _buildEmptyState();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        title: Text('${widget.childName} – Compare'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Comparison',
            onPressed: _isExporting ? null : _shareComparison,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Comparison card ──
            Expanded(
              child: AnimatedBuilder(
                animation: _cardEntry,
                builder: (context, child) {
                  return Opacity(
                    opacity: _cardEntry.value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - _cardEntry.value)),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: RepaintBoundary(
                    key: _repaintKey,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF26A69A),
                            Color(0xFF7E57C2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF26A69A)
                                .withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Child name
                          Text(
                            widget.childName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Side-by-side photos
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildPhotoColumn(
                                    year: _leftYear,
                                  ),
                                ),
                                const Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white54,
                                    size: 20,
                                  ),
                                ),
                                Expanded(
                                  child: _buildPhotoColumn(
                                    year: _rightYear,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Watermark
                          const Text(
                            'SeeMeGrow',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Year selectors ──
            AnimatedBuilder(
              animation: _chipsEntry,
              builder: (context, child) {
                return Opacity(
                  opacity: _chipsEntry.value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _chipsEntry.value)),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildChipRow(
                      label: 'Before',
                      selectedYear: _leftYear,
                      onSelected: (year) =>
                          setState(() => _leftYear = year),
                    ),
                    const SizedBox(height: 12),
                    _buildChipRow(
                      label: 'After',
                      selectedYear: _rightYear,
                      onSelected: (year) =>
                          setState(() => _rightYear = year),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Share button ──
            AnimatedBuilder(
              animation: _buttonEntry,
              builder: (context, child) {
                return Opacity(
                  opacity: _buttonEntry.value,
                  child: Transform.scale(
                    scale: 0.9 + 0.1 * _buttonEntry.value,
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: _buildShareButton(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Photo column with AnimatedSwitcher
  // ---------------------------------------------------------------------------
  Widget _buildPhotoColumn({required int year}) {
    return Column(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            child: _buildPhoto(year),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _yearLabel(year),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _calendarYear(year),
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Gradient share button
  // ---------------------------------------------------------------------------
  Widget _buildShareButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF26A69A), Color(0xFF7E57C2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF26A69A).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isExporting ? null : _shareComparison,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isExporting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.share, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Share Comparison',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
