import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Smart Safe Media Frame
/// ----------------------
/// - يمنع قص الوجه / اليد / الرأس
/// - الصورة الأصلية دائمًا كاملة
/// - خلفية ذكية (Blur illusion + Gradient)
/// - Mobile-first (9:16)
/// - صالح للعرض + التصدير
class SafeMediaFrame extends StatelessWidget {
  final Uint8List imageBytes;
  final String? label;
  final double aspectRatio;

  const SafeMediaFrame({
    super.key,
    required this.imageBytes,
    this.label,
    this.aspectRatio = 9 / 16,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 🔹 Background fill (blur illusion بدون ImageFiltered)
        Positioned.fill(
          child: Opacity(
            opacity: 0.25,
            child: Image.memory(
              imageBytes,
              fit: BoxFit.cover,
            ),
          ),
        ),

        // 🔹 Soft gradient overlay (سينمائي)
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.15),
                  Colors.transparent,
                  Colors.black.withOpacity(0.25),
                ],
              ),
            ),
          ),
        ),

        // 🔹 Main image (SAFE – no crop ever)
        Center(
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Image.memory(
              imageBytes,
              fit: BoxFit.contain,
            ),
          ),
        ),

        // 🔹 Optional label (Age / Year)
        if (label != null)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
