import 'dart:io';
import 'package:ffmpeg_kit_flutter_min/ffmpeg_kit.dart';

class TimelineVideoGenerator {
  final List<File> images;
  final File output;

  TimelineVideoGenerator({
    required this.images,
    required this.output,
  });

  /// إعدادات الفيديو
  static const int width = 1080;
  static const int height = 1920;
  static const double secondsPerImage = 1.2;

  Future<void> generate() async {
    if (images.isEmpty) {
      throw Exception('No images to generate video.');
    }

    // ملف قائمة الصور
    final listFile = File('${output.parent.path}/images.txt');
    final buffer = StringBuffer();

    for (final img in images) {
      buffer.writeln("file '${img.path}'");
      buffer.writeln("duration $secondsPerImage");
    }
    // تكرار آخر صورة لضمان مدة صحيحة
    buffer.writeln("file '${images.last.path}'");

    await listFile.writeAsString(buffer.toString());

    if (await output.exists()) {
      await output.delete();
    }

    final cmd = '''
      -y
      -f concat
      -safe 0
      -i "${listFile.path}"
      -vf "scale=$width:$height:force_original_aspect_ratio=decrease,
           pad=$width:$height:(ow-iw)/2:(oh-ih)/2,
           format=yuv420p"
      -movflags +faststart
      "${output.path}"
    ''';

    final session = await FFmpegKit.execute(cmd);
    final rc = await session.getReturnCode();

    if (rc == null || !rc.isValueSuccess()) {
      throw Exception('FFmpeg failed with code $rc');
    }
  }
}
