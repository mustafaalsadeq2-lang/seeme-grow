import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/child.dart';

class TimelineMovieScreen extends StatefulWidget {
  final Child child;

  const TimelineMovieScreen({
    super.key,
    required this.child,
  });

  @override
  State<TimelineMovieScreen> createState() =>
      _TimelineMovieScreenState();
}

class _TimelineMovieScreenState extends State<TimelineMovieScreen>
    with SingleTickerProviderStateMixin {
  late final List<MapEntry<int, String>> _photos;

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  Timer? _timer;
  int _index = 0;
  bool _playing = true;
  bool _finished = false;

  @override
  void initState() {
    super.initState();

    _photos = widget.child.yearPhotos.entries
        .where((e) => e.value.trim().isNotEmpty)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _scale = Tween<double>(
      begin: 1.04,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    if (_photos.isNotEmpty) {
      _controller.forward();
      _start();
    }
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        if (!_playing || _finished) return;

        if (_index < _photos.length - 1) {
          setState(() => _index++);
          _controller
            ..reset()
            ..forward();
        } else {
          setState(() {
            _playing = false;
            _finished = true;
          });
          _timer?.cancel();
        }
      },
    );
  }

  void _togglePlay() {
    if (_finished) return;
    setState(() => _playing = !_playing);
  }

  void _restart() {
    setState(() {
      _index = 0;
      _playing = true;
      _finished = false;
    });
    _controller
      ..reset()
      ..forward();
    _start();
  }

  void _goBack() {
    Navigator.pop(context, true);
  }

  String _ageText(int year) {
    if (year == 0) return 'Newborn';

    final birth = widget.child.birthDate;
    final date = DateTime(
      birth.year + year,
      birth.month,
      birth.day,
    );

    int y = date.year - birth.year;
    int m = date.month - birth.month;
    int d = date.day - birth.day;

    if (d < 0) {
      m--;
      d += DateTime(date.year, date.month, 0).day;
    }
    if (m < 0) {
      y--;
      m += 12;
    }

    final parts = <String>[];
    if (y > 0) parts.add('$y years');
    if (m > 0) parts.add('$m months');
    if (d > 0) parts.add('$d days');

    return parts.join(' · ');
  }

  Widget _buildCinematicImage(File file) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(file, fit: BoxFit.cover),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(color: Colors.black.withOpacity(0.18)),
        ),
        Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return Opacity(
                opacity: _fade.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: Image.file(
                    file,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return const Icon(
                        Icons.broken_image,
                        size: 80,
                        color: Colors.white54,
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_photos.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No photos')),
      );
    }

    final entry = _photos[_index];
    final year = entry.key;
    final file = File(entry.value);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _togglePlay,
        onLongPress: _restart,
        child: Stack(
          children: [
            Positioned.fill(
              child: file.existsSync()
                  ? _buildCinematicImage(file)
                  : const Icon(
                      Icons.broken_image,
                      size: 80,
                      color: Colors.white54,
                    ),
            ),

            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              left: 24,
              right: 24,
              bottom: 56,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.child.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _ageText(year),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            if (!_playing && !_finished)
              const Center(
                child: Icon(
                  Icons.play_arrow,
                  size: 80,
                  color: Colors.white70,
                ),
              ),

            if (_finished)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.55),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 56,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Beautiful memories',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap and hold to watch again',
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  color: Colors.white,
                  onPressed: _goBack,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
