import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/child.dart';
import '../storage/local_storage_service.dart';

class GrowthStatsScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const GrowthStatsScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<GrowthStatsScreen> createState() => _GrowthStatsScreenState();
}

class _GrowthStatsScreenState extends State<GrowthStatsScreen>
    with TickerProviderStateMixin {
  Child? _child;
  bool _loading = true;

  late AnimationController _entryController;
  late Animation<double> _ringEntry;
  late Animation<double> _statsEntry;
  late Animation<double> _milestoneEntry;
  late Animation<double> _recentEntry;

  late AnimationController _ringController;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _ringEntry = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    );

    _statsEntry = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.15, 0.65, curve: Curves.easeOutCubic),
    );

    _milestoneEntry = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
    );

    _recentEntry = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
    );

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _ringAnimation = CurvedAnimation(
      parent: _ringController,
      curve: Curves.easeOutCubic,
    );

    _loadChild();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------

  Future<void> _loadChild() async {
    final children = await LocalStorageService.loadChildren();
    final match = children.where((c) => c.localId == widget.childId);

    if (!mounted) return;

    if (match.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    setState(() {
      _child = match.first;
      _loading = false;
    });

    _entryController.forward();
    _ringController.forward();
  }

  // ---------------------------------------------------------------------------
  // Computed properties
  // ---------------------------------------------------------------------------

  List<int> get _completedYearsList {
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

  int get _completedYears => _completedYearsList.length;

  int get _remainingYears => 19 - _completedYears;

  double get _progressPercent =>
      _completedYears > 0 ? _completedYears / 19 : 0;

  int get _currentAge {
    if (_child == null) return 0;
    final birth = _child!.birthDate;
    final now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age.clamp(0, 18);
  }

  /// Returns (year, daysUntil) or null if none
  ({int year, int days})? get _nextMilestone {
    if (_child == null) return null;
    final now = DateTime.now();
    final birth = _child!.birthDate;

    // Find the next year (from currentAge onward) that has no photo
    for (int y = _currentAge; y <= 18; y++) {
      final path = _child!.yearPhotos[y]?.trim() ?? '';
      final hasPhoto = path.isNotEmpty && File(path).existsSync();
      if (!hasPhoto) {
        // Calculate the birthday for this year
        final targetBirthday = DateTime(birth.year + y, birth.month, birth.day);
        if (targetBirthday.isAfter(now)) {
          final days = targetBirthday.difference(now).inDays;
          return (year: y, days: days);
        }
        // If birthday already passed this year, it's overdue — still show it
        return (year: y, days: 0);
      }
    }
    return null; // all captured
  }

  /// Returns (year, path) of the highest year with a valid photo, or null
  ({int year, String path})? get _mostRecentPhoto {
    final completed = _completedYearsList;
    if (completed.isEmpty) return null;
    final year = completed.last;
    return (year: year, path: _child!.yearPhotos[year]!);
  }

  String get _motivationalMessage {
    final pct = _progressPercent;
    if (pct == 0) return 'Start capturing memories today!';
    if (pct <= 0.25) return 'Great start! Keep the memories flowing.';
    if (pct <= 0.50) return "You're building something beautiful.";
    if (pct <= 0.75) return 'More than halfway there!';
    if (pct < 1.0) return 'Almost complete! Just a few more.';
    return 'Amazing! Every moment captured.';
  }

  String _yearLabel(int year) => year == 0 ? 'Birth' : 'Year $year';

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('${widget.childName} – Stats')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_child == null) {
      return Scaffold(
        appBar: AppBar(title: Text('${widget.childName} – Stats')),
        body: const Center(child: Text('Child not found')),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('${widget.childName} – Stats')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Progress Ring Card ──
            _buildAnimatedCard(
              animation: _ringEntry,
              child: _buildProgressCard(theme),
            ),

            const SizedBox(height: 16),

            // ── Completed / Remaining Row ──
            _buildAnimatedCard(
              animation: _statsEntry,
              child: _buildStatsRow(theme),
            ),

            const SizedBox(height: 16),

            // ── Next Milestone ──
            _buildAnimatedCard(
              animation: _milestoneEntry,
              child: _buildMilestoneCard(theme),
            ),

            const SizedBox(height: 16),

            // ── Most Recent Photo ──
            _buildAnimatedCard(
              animation: _recentEntry,
              child: _buildRecentPhotoCard(theme),
            ),

            const SizedBox(height: 24),

            // ── Motivational Message ──
            AnimatedBuilder(
              animation: _recentEntry,
              builder: (context, child) {
                return Opacity(
                  opacity: _recentEntry.value,
                  child: child,
                );
              },
              child: Text(
                _motivationalMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Animated wrapper
  // ---------------------------------------------------------------------------

  Widget _buildAnimatedCard({
    required Animation<double> animation,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, c) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animation.value)),
            child: c,
          ),
        );
      },
      child: child,
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Progress Ring Card
  // ---------------------------------------------------------------------------

  Widget _buildProgressCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF26A69A), Color(0xFF7E57C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF26A69A).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: AnimatedBuilder(
              animation: _ringAnimation,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ProgressRingPainter(
                    progress: _progressPercent * _ringAnimation.value,
                    strokeWidth: 10,
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_completedYears',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'of 19',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Memories Captured',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Stats Row (Completed / Remaining)
  // ---------------------------------------------------------------------------

  Widget _buildStatsRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme: theme,
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            value: '$_completedYears',
            label: 'Completed',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme: theme,
            icon: Icons.radio_button_unchecked,
            iconColor: Colors.orange,
            value: '$_remainingYears',
            label: 'Remaining',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Next Milestone Card
  // ---------------------------------------------------------------------------

  Widget _buildMilestoneCard(ThemeData theme) {
    final milestone = _nextMilestone;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF26A69A).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.cake_outlined,
                color: Color(0xFF26A69A),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Milestone',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    milestone != null
                        ? milestone.days > 0
                            ? '${_yearLabel(milestone.year)} in ${milestone.days} days'
                            : '${_yearLabel(milestone.year)} – capture it now!'
                        : 'All milestones reached!',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Most Recent Photo Card
  // ---------------------------------------------------------------------------

  Widget _buildRecentPhotoCard(ThemeData theme) {
    final recent = _mostRecentPhoto;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 64,
                height: 64,
                child: recent != null
                    ? Image.file(
                        File(recent.path),
                        fit: BoxFit.cover,
                        cacheWidth: 200,
                        errorBuilder: (_, __, ___) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.broken_image,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      )
                    : Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.photo_outlined,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.3),
                          size: 28,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Most Recent Memory',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recent != null
                        ? '${_yearLabel(recent.year)} · ${_child!.birthDate.year + recent.year}'
                        : 'No memories yet',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom painter for circular progress ring
// ---------------------------------------------------------------------------

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color foregroundColor;

  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Foreground arc
    if (progress > 0) {
      final fgPaint = Paint()
        ..color = foregroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2, // start from top
        sweepAngle,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
