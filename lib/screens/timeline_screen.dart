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

    _loadChild(initial: true);
  }

  @override
  void dispose() {
    _progressController.dispose();
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

  @override
  Widget build(BuildContext context) {
    // 🔹 Loading Skeleton (احترافي – بدون شاشة بيضاء)
    if (_loading || _child == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Timeline')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView.builder(
            itemCount: 6,
            itemBuilder: (_, __) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 88,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
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
                  MaterialPageRoute(
                    builder: (_) => TimelineMovieScreen(child: child),
                  ),
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
              itemBuilder: (context, year) {
                final isBirth = year == 0;
                final hasPhoto = _hasPhoto(year);
                final isFuture = year > currentYear;
                final isCurrent = year == currentYear;

                final imagePath = child.yearPhotos[year];
                final title = isBirth ? 'Birth' : 'Year $year';
                final enabled = !isFuture;

                return Card(
                  elevation: isCurrent ? 4 : 1,
                  color: isCurrent ? Colors.purple.shade50 : null,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: enabled
                        ? () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => YearDetailScreen(
                                  child: child,
                                  year: year,
                                ),
                              ),
                            );
                            _loadChild();
                          }
                        : null,
                    child: SizedBox(
                      height: 88,
                      child: Row(
                        children: [
                          Container(
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
                                      topLeft: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                    ),
                                    child: Image.file(
                                      File(imagePath!),
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter,
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
                                            const EdgeInsets.only(left: 8),
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.purple,
                                          borderRadius:
                                              BorderRadius.circular(12),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
