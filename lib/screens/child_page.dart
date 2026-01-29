import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/child.dart';
import '../repositories/photo_repository.dart';
import '../repositories/cloud_photo_repository.dart';
import 'timeline_screen.dart';
import 'timeline_movie_screen.dart';

class ChildPage extends StatefulWidget {
  final Child child;

  const ChildPage({
    super.key,
    required this.child,
  });

  @override
  State<ChildPage> createState() => _ChildPageState();
}

class _ChildPageState extends State<ChildPage> {
  final PhotoRepository _photoRepository = CloudPhotoRepository();
  bool _hasChanges = false;

  Child get child => widget.child;

  @override
  void initState() {
    super.initState();

    debugPrint('🧠 ChildPage opened');
    debugPrint('🧒 Child name: ${child.name}');
    debugPrint('🆔 localId: ${child.localId}');
    debugPrint('☁️ cloudId: ${child.cloudId}');
  }

  String _ageText() {
    final now = DateTime.now();
    final birth = child.birthDate;

    int years = now.year - birth.year;
    int months = now.month - birth.month;
    int days = now.day - birth.day;

    if (days < 0) {
      months--;
      days += DateTime(now.year, now.month, 0).day;
    }
    if (months < 0) {
      years--;
      months += 12;
    }

    final parts = <String>[];
    if (years > 0) parts.add('$years years');
    if (months > 0) parts.add('$months months');
    if (days > 0) parts.add('$days days');

    return parts.isEmpty ? 'Newborn' : parts.join(' · ');
  }

  bool get _hasPhotos =>
      child.yearPhotos.values.any((p) => p.trim().isNotEmpty);

  void _goBack() {
    Navigator.pop(context, _hasChanges);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: _goBack,
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                child.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  const SizedBox(height: 12),

                  Text(
                    _ageText(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Born on ${child.birthDate.toLocal().toString().split(' ')[0]}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  if (_hasPhotos)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.play_circle_fill),
                        label: const Text(
                          'Play Memories',
                          style: TextStyle(fontSize: 16),
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TimelineMovieScreen(child: child),
                            ),
                          );
                          _hasChanges = true;
                        },
                      ),
                    ),

                  if (_hasPhotos) const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.timeline),
                      label: const Text(
                        'View Growth Timeline',
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TimelineScreen(
                              childId: child.localId, // ✅ FIX FINAL
                            ),
                          ),
                        );
                        _hasChanges = true;
                      },
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
