import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/child.dart';
import 'timeline_video_generator.dart';

class ExportResult {
  final File? posterImage;
  final File? videoFile;

  ExportResult({this.posterImage, this.videoFile});
}

class ExportService {
  /// يجمع صور السنوات المرتبة (يتجاهل السنوات بدون صورة)
  static List<MapEntry<int, File>> collectYearImages(Child child) {
    final entries = child.yearPhotos.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return entries
        .where((e) => e.value.trim().isNotEmpty)
        .map((e) => MapEntry(e.key, File(e.value)))
        .where((e) => e.value.existsSync())
        .toList();
  }

  /// إنشاء Poster طويل (صورة واحدة لكل سنة عموديًا)
  static Future<File?> createTimelinePoster(Child child) async {
    final items = collectYearImages(child);
    if (items.isEmpty) return null;

    final images = <ui.Image>[];
    for (final item in items) {
      final bytes = await item.value.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      images.add(frame.image);
    }

    // أبعاد موحّدة
    const double targetWidth = 1080;
    const double spacing = 16;

    double yOffset = 0;
    final heights = <double>[];

    for (final img in images) {
      final ratio = img.height / img.width;
      final h = targetWidth * ratio;
      heights.add(h);
      yOffset += h + spacing;
    }

    final totalHeight = yOffset - spacing;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, targetWidth, totalHeight),
    );

    final paint = Paint()..filterQuality = FilterQuality.high;

    double currentY = 0;
    for (int i = 0; i < images.length; i++) {
      final img = images[i];
      final h = heights[i];

      final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
      final dst = Rect.fromLTWH(0, currentY, targetWidth, h);
      canvas.drawImageRect(img, src, dst, paint);

      currentY += h + spacing;
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(
      targetWidth.toInt(),
      totalHeight.toInt(),
    );
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    if (pngBytes == null) return null;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/timeline_poster_${child.id}.png');
    await file.writeAsBytes(pngBytes.buffer.asUint8List());

    return file;
  }

  /// إنشاء فيديو فعلي MP4
  static Future<File?> createTimelineVideo(Child child) async {
    final items = collectYearImages(child);
    if (items.isEmpty) return null;

    final dir = await getTemporaryDirectory();
    final output = File('${dir.path}/timeline_${child.id}.mp4');

    final generator = TimelineVideoGenerator(
      images: items.map((e) => e.value).toList(),
      output: output,
    );

    await generator.generate();
    return output;
  }

  /// العملية الكاملة (Poster + Video)
  static Future<ExportResult> exportAll(Child child) async {
    final poster = await createTimelinePoster(child);
    final video = await createTimelineVideo(child);
    return ExportResult(posterImage: poster, videoFile: video);
  }
}
