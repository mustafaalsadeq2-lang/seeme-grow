import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/child.dart';
import '../storage/local_storage_service.dart';
import 'comparison_screen.dart';
import 'growth_stats_screen.dart';
import 'timeline_movie_screen.dart';
import 'voice_note_screen.dart';
import 'year_detail_screen.dart';

class TimelineScreen extends StatefulWidget {
  final String childId; // localId

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
  bool _loading = true;

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

  Future<void> _loadChild({bool initial = false}) async {
    final children = await LocalStorageService.loadChildren();
    final child =
        children.firstWhere((c) => c.localId == widget.childId);

    if (!mounted) return;

    final completedNow = child.yearPhotos.values
        .where((p) => p.trim().isNotEmpty)
        .length;

    if (!initial && completedNow > _lastCompletedYears) {
      _celebrate(
        previous: _lastCompletedYears,
        current: completedNow,
      );
    }

    setState(() {
      _child = child;
      _loading = false;
      _lastCompletedYears = completedNow;
    });

    _progressController.forward(from: 0);
    _listController.forward(from: 0);
  }

  int get _currentYear {
    final birth = _child!.birthDate;
    final now = DateTime.now();

    int age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }

    return age.clamp(0, 18);
  }

  bool _hasPhoto(int year) {
    final path = _child?.yearPhotos[year];
    return path != null && path.trim().isNotEmpty;
  }

  int get _completedYears => _lastCompletedYears;

  void _celebrate({
    required int previous,
    required int current,
  }) {
    HapticFeedback.lightImpact();

    final currentYear = _currentYear;
    String message;

    if (current == 1) {
      message = '✨ First memory saved';
    } else if (current == 19) {
      message = '🏁 All memories completed\nA lifetime captured';
    } else if (current == currentYear + 1) {
      message = '🎉 Year $currentYear completed';
    } else {
      message = '💜 Memory saved';
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
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

  Route<String> _createZoomRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          ),
          child: child,
        );
      },
    );
  }

  Animation<double> _itemAnimation(int index) {
    final start = (index * 0.04).clamp(0.0, 0.6);
    final end = (start + 0.4).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _listController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  Widget _buildShimmerSkeleton() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform:
                  _SlidingGradientTransform(_shimmerController.value),
            ).createShader(bounds);
          },
          child: child!,
        );
      },
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
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
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
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 150,
                      height: 12,
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

  // ---------------------------------------------------------------------------
  // Progress Header
  // ---------------------------------------------------------------------------

  Widget _buildProgressHeader() {
    final theme = Theme.of(context);
    final completed = _completedYears;
    final percent = (completed / 19 * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$completed of 19 memories',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (_, __) {
              final progressTarget = completed / 19;
              return Container(
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor:
                        (progressTarget * _progressAnimation.value)
                            .clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF26A69A),
                            Color(0xFF7E57C2),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF26A69A)
                                .withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
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

  // ---------------------------------------------------------------------------
  // Milestone Badges
  // ---------------------------------------------------------------------------

  static const _milestones = <int, (IconData, String)>{
    0: (Icons.cake, 'Birth'),
    1: (Icons.star, 'First Year'),
    5: (Icons.auto_awesome, 'Half Decade'),
    10: (Icons.emoji_events, 'Decade'),
  };

  bool _hasMilestone(int year) => _milestones.containsKey(year);

  Widget _milestoneBadge(int year) {
    final theme = Theme.of(context);
    final milestone = _milestones[year];
    if (milestone == null) return const SizedBox.shrink();

    final (icon, label) = milestone;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Year Card
  // ---------------------------------------------------------------------------

  Widget _buildYearItem(int year) {
    final anim = _itemAnimation(year);

    return AnimatedBuilder(
      animation: anim,
      builder: (context, cardChild) {
        return Opacity(
          opacity: anim.value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - anim.value)),
            child: cardChild,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasMilestone(year)) _milestoneBadge(year),
          _buildYearCard(year),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildYearCard(int year) {
    final theme = Theme.of(context);
    final child = _child!;
    final isBirth = year == 0;
    final hasPhoto = _hasPhoto(year);
    final isFuture = year > _currentYear;
    final isCurrent = year == _currentYear;
    final imagePath = child.yearPhotos[year];
    final title = isBirth ? 'Birth' : 'Year $year';
    final gregorianYear = '(${child.birthDate.year + year})';
    final enabled = !isFuture;

    const teal = Color(0xFF26A69A);

    return _TapScaleCard(
      enabled: enabled,
      onTap: enabled
          ? () async {
              if (hasPhoto) {
                final result = await Navigator.push<String>(
                  context,
                  _createZoomRoute(
                    _PhotoZoomScreen(
                      imagePath: imagePath!,
                      heroTag: 'year_photo_${widget.childId}_$year',
                      title: isBirth
                          ? '${child.name} · Birth'
                          : '${child.name} · Year $year',
                      childId: widget.childId,
                      childName: child.name,
                      year: year,
                    ),
                  ),
                );
                if (result == 'edit' && mounted) {
                  await Navigator.push(
                    context,
                    _createRoute(
                      YearDetailScreen(child: child, year: year),
                    ),
                  );
                }
              } else {
                await Navigator.push(
                  context,
                  _createRoute(
                    YearDetailScreen(child: child, year: year),
                  ),
                );
              }
              _loadChild();
            }
          : null,
      child: Card(
        elevation: isCurrent ? 3 : 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: null, // Handled by _TapScaleCard
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail
                Hero(
                  tag: 'year_photo_${widget.childId}_$year',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: hasPhoto
                          ? Image.file(
                              File(imagePath!),
                              fit: BoxFit.cover,
                              cacheWidth: 180,
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: isFuture
                                    ? null
                                    : LinearGradient(
                                        colors: [
                                          theme.colorScheme.primary
                                              .withValues(alpha: 0.1),
                                          theme.colorScheme.primary
                                              .withValues(alpha: 0.05),
                                        ],
                                      ),
                                color: isFuture
                                    ? theme.colorScheme.onSurface
                                        .withValues(alpha: 0.06)
                                    : null,
                              ),
                              child: Icon(
                                isFuture
                                    ? Icons.lock
                                    : Icons.add_photo_alternate,
                                size: 24,
                                color: theme.colorScheme.onSurface
                                    .withValues(
                                        alpha: isFuture ? 0.3 : 0.4),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Now',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        gregorianYear,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (hasPhoto)
                        const Row(
                          children: [
                            Text(
                              'Memory saved',
                              style: TextStyle(
                                fontSize: 12,
                                color: teal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: teal,
                            ),
                          ],
                        )
                      else
                        Text(
                          isFuture ? 'Locked' : 'Add memory',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface
                                .withValues(
                                    alpha: isFuture ? 0.3 : 0.5),
                          ),
                        ),
                    ],
                  ),
                ),
                // Chevron
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.3),
                ),
              ],
            ),
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
    if (_loading || _child == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Timeline')),
        body: _buildShimmerSkeleton(),
      );
    }

    final child = _child!;

    return Scaffold(
      appBar: AppBar(
        title: Text('${child.name} Timeline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Growth Stats',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GrowthStatsScreen(
                    childId: widget.childId,
                    childName: child.name,
                  ),
                ),
              );
            },
          ),
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
      body: Column(
        children: [
          _buildProgressHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              itemCount: 19,
              cacheExtent: 400,
              itemBuilder: (_, year) => _buildYearItem(year),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tap-scale feedback widget: scales down on press, bounces back on release
// ---------------------------------------------------------------------------
class _TapScaleCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  const _TapScaleCard({
    required this.child,
    this.onTap,
    this.enabled = true,
  });

  @override
  State<_TapScaleCard> createState() => _TapScaleCardState();
}

class _TapScaleCardState extends State<_TapScaleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: child,
          );
        },
        child: widget.child,
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
  final TransformationController _transformController =
      TransformationController();
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
    final currentScale =
        _transformController.value.getMaxScaleOnAxis();

    final Matrix4 target;
    if (currentScale > 1.5) {
      target = Matrix4.identity();
    } else {
      const scale = 3.0;
      final pos = _doubleTapDetails!.localPosition;
      final x = -pos.dx * (scale - 1);
      final y = -pos.dy * (scale - 1);
      target = Matrix4.identity()
        ..translateByDouble(x, y, 0.0, 0.0)
        ..scaleByDouble(scale, scale, 1.0, 1.0);
    }

    _matrixAnimation = Matrix4Tween(
      begin: _transformController.value,
      end: target,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
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
                    child: Image.file(
                      File(widget.imagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Close button – top left
          Positioned(
            top: padding.top + 12,
            left: 12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),

          // Voice note button – top right (second)
          Positioned(
            top: padding.top + 12,
            right: 60,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VoiceNoteScreen(
                      childId: widget.childId,
                      childName: widget.childName,
                      year: widget.year,
                    ),
                  ),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

          // Edit button – top right
          Positioned(
            top: padding.top + 12,
            right: 12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context, 'edit'),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

          // Title – bottom center
          Positioned(
            bottom: padding.bottom + 28,
            left: 24,
            right: 24,
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
      bounds.width * (2 * percent - 1),
      0,
      0,
    );
  }
}
