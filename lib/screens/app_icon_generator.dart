import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class AppIconGenerator extends StatelessWidget {
  const AppIconGenerator({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('App Icon Preview')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Large preview
            Container(
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
                  painter: _AppIconPainter(),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'SeeMe Grow',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '1024 x 1024 icon design',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 40),
            // Small previews row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _preview(60, 13),
                const SizedBox(width: 16),
                _preview(40, 9),
                const SizedBox(width: 16),
                _preview(29, 6),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview(double size, double radius) {
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
              painter: const _AppIconPainter(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${size.toInt()}pt',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

class _AppIconPainter extends CustomPainter {
  const _AppIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    // -- Background: teal → purple gradient with rounded rect clip --
    final bgRect = Rect.fromLTWH(0, 0, s, s);
    final cornerRadius = s * (180 / 1024);
    final rrect = RRect.fromRectAndRadius(bgRect, Radius.circular(cornerRadius));

    canvas.clipRRect(rrect);

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF26A69A), Color(0xFF7E57C2)],
      ).createShader(bgRect);

    canvas.drawRect(bgRect, bgPaint);

    // -- Subtle radial highlight in upper-left --
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

    // -- Seedling / sprout icon --
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

    // Center point for the sprout
    final cx = s * 0.5;
    final baseY = s * 0.58;

    // -- Stem --
    final stemPath = Path();
    stemPath.moveTo(cx, baseY);
    stemPath.cubicTo(
      cx, baseY - s * 0.12,
      cx - s * 0.01, baseY - s * 0.22,
      cx, baseY - s * 0.30,
    );
    canvas.drawPath(stemPath, strokePaint);

    // -- Left leaf --
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

    // -- Right leaf --
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

    // -- Top bud (small circle at top of stem) --
    canvas.drawCircle(
      Offset(cx, baseY - s * 0.31),
      s * 0.022,
      paint,
    );

    // -- Ground arc --
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
