import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/child.dart';
import '../storage/local_storage_service.dart';
import '../utils/app_tokens.dart';

// Gradient colours for the comparison card.
const _kGradStart = Color(0xFF0F4F45);
const _kGradEnd   = Color(0xFF1a6b5e);

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
  bool _isSaving = false;

  final GlobalKey _repaintKey = GlobalKey();

  late AnimationController _entryController;
  late Animation<double> _cardEntry;
  late Animation<double> _chipsEntry;
  late Animation<double> _buttonEntry;

  @override
  void initState() {
    super.initState();
    _leftYear  = 0;
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

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadChild() async {
    final children = await LocalStorageService.loadChildren();
    final match    = children.where((c) => c.localId == widget.childId);

    if (!mounted) return;

    if (match.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    final child     = match.first;
    final available = <int>[];
    for (final e in child.yearPhotos.entries) {
      final path = e.value.trim();
      if (path.isNotEmpty && File(path).existsSync()) available.add(e.key);
    }
    available.sort();

    setState(() {
      _child     = child;
      _loading   = false;
      _leftYear  = available.isNotEmpty ? available.first : 0;
      _rightYear = available.length >= 2 ? available.last : _leftYear;
    });

    if (available.length >= 2) _entryController.forward();
  }

  List<int> get _availableYears {
    if (_child == null) return [];
    final years = <int>[];
    for (final e in _child!.yearPhotos.entries) {
      final path = e.value.trim();
      if (path.isNotEmpty && File(path).existsSync()) years.add(e.key);
    }
    years.sort();
    return years;
  }

  bool _yearHasPhoto(int year) {
    final path = _child?.yearPhotos[year];
    if (path == null || path.trim().isEmpty) return false;
    return File(path).existsSync();
  }

  String _yearLabel(int year)    => year == 0 ? 'Birth' : 'Age $year';
  String _calendarYear(int year) => (_child!.birthDate.year + year).toString();

  // ── Save image ────────────────────────────────────────────────────────────

  Future<void> _saveImage() async {
    setState(() => _isSaving = true);
    try {
      final boundary = _repaintKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final image    = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to capture image');

      final dir  = await getTemporaryDirectory();
      final ts   = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/compare_${widget.childId}_$ts.png');
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
            content: Text('Could not save image: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Loading / empty states ────────────────────────────────────────────────

  Widget _buildLoadingSkeleton() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.childName,
          style: serif(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.childName,
          style: serif(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.compare_arrows, size: 64, color: T.ink4),
              const SizedBox(height: 16),
              Text(
                'Add at least 2 photos\nto compare growth',
                textAlign: TextAlign.center,
                style: serif(fontSize: 17, color: T.ink3),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Polaroid photo widget ─────────────────────────────────────────────────

  Widget _buildPolaroid(int year) {
    final path    = _child?.yearPhotos[year];
    final hasFile = path != null && path.trim().isNotEmpty && File(path).existsSync();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 28),
      child: Column(
        children: [
          // Photo area
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: hasFile
                  ? AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Image.file(
                        File(path),
                        key: ValueKey(year),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        alignment: Alignment.topCenter,
                        cacheWidth: 400,
                      ),
                    )
                  : Container(
                      color: const Color(0xFFF0EDE8),
                      child: const Center(
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 32,
                          color: Color(0xFFCCC8C0),
                        ),
                      ),
                    ),
            ),
          ),

          // Year label
          const SizedBox(height: 8),
          Text(
            _yearLabel(year),
            style: serif(
              fontSize: 11,
              color: T.ink3,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            _calendarYear(year),
            style: const TextStyle(
              fontSize: 10,
              color: T.ink4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Year chip row ─────────────────────────────────────────────────────────

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
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: T.ink3,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 19,
            itemBuilder: (_, year) {
              final hasPhoto  = _yearHasPhoto(year);
              final isSelected= selectedYear == year;
              final chipLabel = year == 0 ? 'Birth' : '$year';

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: hasPhoto
                      ? () {
                          HapticFeedback.lightImpact();
                          onSelected(year);
                        }
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _kGradStart
                          : hasPhoto
                              ? Colors.white
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? _kGradStart
                            : hasPhoto
                                ? T.hairline
                                : Colors.transparent,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: _kGradStart.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      chipLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : hasPhoto
                                ? T.ink
                                : T.ink4,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoadingSkeleton();
    if (_availableYears.length < 2) return _buildEmptyState();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.childName,
          style: serif(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Comparison card ───────────────────────────────────────────
            Expanded(
              child: AnimatedBuilder(
                animation: _cardEntry,
                builder: (_, child) => Opacity(
                  opacity: _cardEntry.value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - _cardEntry.value)),
                    child: child,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: RepaintBoundary(
                    key: _repaintKey,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kGradStart, _kGradEnd],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: _kGradStart.withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                      child: Column(
                        children: [
                          // Child name
                          Text(
                            widget.childName,
                            style: serif(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Polaroid pair ─────────────────────────────
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(child: _buildPolaroid(_leftYear)),
                                const SizedBox(width: 14),
                                // Arrow
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 28, height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white70,
                                        size: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                Expanded(child: _buildPolaroid(_rightYear)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Watermark
                          Text(
                            'SeeMeGrow',
                            style: serif(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.4),
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

            // ── Year selectors ────────────────────────────────────────────
            AnimatedBuilder(
              animation: _chipsEntry,
              builder: (_, child) => Opacity(
                opacity: _chipsEntry.value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - _chipsEntry.value)),
                  child: child,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildChipRow(
                      label: 'BEFORE',
                      selectedYear: _leftYear,
                      onSelected: (y) => setState(() => _leftYear = y),
                    ),
                    const SizedBox(height: 12),
                    _buildChipRow(
                      label: 'AFTER',
                      selectedYear: _rightYear,
                      onSelected: (y) => setState(() => _rightYear = y),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Save image button ─────────────────────────────────────────
            AnimatedBuilder(
              animation: _buttonEntry,
              builder: (_, child) => Opacity(
                opacity: _buttonEntry.value,
                child: Transform.scale(
                  scale: 0.9 + 0.1 * _buttonEntry.value,
                  child: child,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: _buildSaveButton(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Save image button ─────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kGradStart, _kGradEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _kGradStart.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSaving ? null : _saveImage,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isSaving
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download_outlined,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Save image',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
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
