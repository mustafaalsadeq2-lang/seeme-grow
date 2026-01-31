import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/child.dart';
import '../storage/local_storage_service.dart';
import 'timeline_movie_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    if (_loading || _child == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Timeline')),
        body: _buildShimmerSkeleton(),
      );
    }

    final child = _child!;
    final progressTarget = _completedYears / 19;
    final currentYear = _currentYear;

    return Scaffold(
      appBar: AppBar(
        title: Text('${child.name} Timeline'),
        actions: [
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Memories captured: $_completedYears of 19',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (_, __) {
                      return LinearProgressIndicator(
                        value:
                            progressTarget * _progressAnimation.value,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade300,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 19,
              cacheExtent: 400,
              itemBuilder: (context, year) {
                final isBirth = year == 0;
                final hasPhoto = _hasPhoto(year);
                final isFuture = year > currentYear;
                final isCurrent = year == currentYear;

                final imagePath = child.yearPhotos[year];
                final title = isBirth ? 'Birth' : 'Year $year';
                final enabled = !isFuture;

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
                  child: _TapScaleCard(
                    enabled: enabled,
                    onTap: enabled
                        ? () async {
                            if (hasPhoto) {
                              final result =
                                  await Navigator.push<String>(
                                context,
                                _createZoomRoute(
                                  _PhotoZoomScreen(
                                    imagePath: imagePath!,
                                    heroTag:
                                        'year_photo_${widget.childId}_$year',
                                    title: isBirth
                                        ? '${child.name} · Birth'
                                        : '${child.name} · Year $year',
                                  ),
                                ),
                              );
                              if (result == 'edit' && mounted) {
                                await Navigator.push(
                                  context,
                                  _createRoute(
                                    YearDetailScreen(
                                      child: child,
                                      year: year,
                                    ),
                                  ),
                                );
                              }
                            } else {
                              await Navigator.push(
                                context,
                                _createRoute(
                                  YearDetailScreen(
                                    child: child,
                                    year: year,
                                  ),
                                ),
                              );
                            }
                            _loadChild();
                          }
                        : null,
                    child: Card(
                      elevation: isCurrent ? 4 : 1,
                      color: isCurrent ? Colors.purple.shade50 : null,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SizedBox(
                        height: 88,
                        child: Row(
                          children: [
                            Hero(
                              tag:
                                  'year_photo_${widget.childId}_$year',
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                  ),
                                  color: Colors.grey.shade300,
                                ),
                                child: hasPhoto
                                    ? ClipRRect(
                                        borderRadius:
                                            const BorderRadius.only(
                                          topLeft:
                                              Radius.circular(16),
                                          bottomLeft:
                                              Radius.circular(16),
                                        ),
                                        child: Image.file(
                                          File(imagePath!),
                                          fit: BoxFit.cover,
                                          alignment:
                                              Alignment.topCenter,
                                          cacheWidth: 264,
                                        ),
                                      )
                                    : Icon(
                                        isFuture
                                            ? Icons.lock
                                            : isBirth
                                                ? Icons.cake
                                                : Icons.photo,
                                        color: Colors.grey,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (isCurrent)
                                        Container(
                                          margin:
                                              const EdgeInsets.only(
                                                  left: 8),
                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.purple,
                                            borderRadius:
                                                BorderRadius.circular(
                                                    12),
                                          ),
                                          child: const Text(
                                            'Current',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    hasPhoto
                                        ? 'Memory saved'
                                        : isFuture
                                            ? 'Not available yet'
                                            : isCurrent
                                                ? 'Add memory for this year'
                                                : 'Add memory',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
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

  const _PhotoZoomScreen({
    required this.imagePath,
    required this.heroTag,
    required this.title,
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
