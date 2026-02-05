import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Standalone screen to preview and export the app icon as a 1024x1024 PNG.
///
/// Usage: navigate here from a debug menu or temporarily set as `home:` in
/// MaterialApp during development.
class GenerateAppIcon extends StatefulWidget {
  const GenerateAppIcon({super.key});

  @override
  State<GenerateAppIcon> createState() => _GenerateAppIconState();
}

class _GenerateAppIconState extends State<GenerateAppIcon> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _saving = false;
  String? _savedPath;

  Future<void> _saveAsPng() async {
    setState(() {
      _saving = true;
      _savedPath = null;
    });

    try {
      // Render icon at 1024x1024 using the painter directly
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(1024, 1024);

      const painter = AppIconPainter();
      painter.paint(canvas, size);

      final picture = recorder.endRecording();
      final image = await picture.toImage(1024, 1024);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) throw Exception('Failed to encode PNG');

      final bytes = byteData.buffer.asUint8List();

      // Save to Documents directory (accessible on both iOS and macOS)
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/seeme_grow_icon_1024.png');
      await file.writeAsBytes(bytes);

      if (mounted) {
        setState(() => _savedPath = file.path);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to: ${file.path}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Generate App Icon')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Large preview ──
              RepaintBoundary(
                key: _repaintKey,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF26A69A).withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: const CustomPaint(
                      size: Size(280, 280),
                      painter: AppIconPainter(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'SeeMe Grow',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '1024 x 1024 · PNG',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),

              const SizedBox(height: 32),

              // ── Small previews ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _sizePreview(60, 13, '60pt'),
                  const SizedBox(width: 16),
                  _sizePreview(40, 9, '40pt'),
                  const SizedBox(width: 16),
                  _sizePreview(29, 6, '29pt'),
                ],
              ),

              const SizedBox(height: 40),

              // ── Save button ──
              FilledButton.icon(
                onPressed: _saving ? null : _saveAsPng,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_alt),
                label: Text(_saving ? 'Saving...' : 'Save as PNG'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),

              if (_savedPath != null) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _savedPath!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sizePreview(double size, double radius, String label) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: CustomPaint(
              size: Size(size, size),
              painter: const AppIconPainter(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Painter — public so it can be used for both preview and offscreen render
// ---------------------------------------------------------------------------

class AppIconPainter extends CustomPainter {
  const AppIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    // -- Background: teal → purple gradient --
    final bgRect = Rect.fromLTWH(0, 0, s, s);
    final cornerRadius = s * (180 / 1024);
    final rrect =
        RRect.fromRectAndRadius(bgRect, Radius.circular(cornerRadius));

    canvas.clipRRect(rrect);

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF26A69A), Color(0xFF7E57C2)],
      ).createShader(bgRect);

    canvas.drawRect(bgRect, bgPaint);

    // -- Subtle radial highlight --
    final highlightPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(s * 0.3, s * 0.25),
        s * 0.5,
        [
          Colors.white.withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0.0),
        ],
      );
    canvas.drawRect(bgRect, highlightPaint);

    // -- Seedling / sprout --
    _drawSeedling(canvas, s);

    // -- "SMG" text --
    _drawText(canvas, s);
  }

  void _drawSeedling(Canvas canvas, double s) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.028
      ..strokeCap = StrokeCap.round;

    final cx = s * 0.5;
    final baseY = s * 0.58;

    // Stem
    final stemPath = Path();
    stemPath.moveTo(cx, baseY);
    stemPath.cubicTo(
      cx, baseY - s * 0.12,
      cx - s * 0.01, baseY - s * 0.22,
      cx, baseY - s * 0.30,
    );
    canvas.drawPath(stemPath, strokePaint);

    // Left leaf
    final leftLeaf = Path();
    final leftAttach = baseY - s * 0.18;
    leftLeaf.moveTo(cx, leftAttach);
    leftLeaf.cubicTo(
      cx - s * 0.08, leftAttach - s * 0.14,
      cx - s * 0.20, leftAttach - s * 0.10,
      cx - s * 0.16, leftAttach - s * 0.02,
    );
    leftLeaf.cubicTo(
      cx - s * 0.12, leftAttach + s * 0.04,
      cx - s * 0.04, leftAttach + s * 0.02,
      cx, leftAttach,
    );
    canvas.drawPath(leftLeaf, paint);

    // Right leaf
    final rightLeaf = Path();
    final rightAttach = baseY - s * 0.26;
    rightLeaf.moveTo(cx, rightAttach);
    rightLeaf.cubicTo(
      cx + s * 0.08, rightAttach - s * 0.14,
      cx + s * 0.20, rightAttach - s * 0.10,
      cx + s * 0.16, rightAttach - s * 0.02,
    );
    rightLeaf.cubicTo(
      cx + s * 0.12, rightAttach + s * 0.04,
      cx + s * 0.04, rightAttach + s * 0.02,
      cx, rightAttach,
    );
    canvas.drawPath(rightLeaf, paint);

    // Top bud
    canvas.drawCircle(
      Offset(cx, baseY - s * 0.31),
      s * 0.022,
      paint,
    );

    // Ground arc
    final groundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.018
      ..strokeCap = StrokeCap.round;

    final groundPath = Path();
    groundPath.moveTo(cx - s * 0.12, baseY + s * 0.02);
    groundPath.quadraticBezierTo(
      cx, baseY + s * 0.06,
      cx + s * 0.12, baseY + s * 0.02,
    );
    canvas.drawPath(groundPath, groundPaint);
  }

  void _drawText(Canvas canvas, double s) {
    final textStyle = ui.TextStyle(
      color: Colors.white,
      fontSize: s * 0.11,
      fontWeight: FontWeight.w700,
      letterSpacing: s * 0.02,
    );

    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
    ))
      ..pushStyle(textStyle)
      ..addText('SMG');

    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: s));

    canvas.drawParagraph(
      paragraph,
      Offset(0, s * 0.66),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
