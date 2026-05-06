import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class T {
  static const bg        = Color(0xFFF7F5F0);
  static const bgSoft    = Color(0xFFFBFAF6);
  static const ink       = Color(0xFF1C1C1E);
  static const ink2      = Color(0xFF3C3C43);
  static const ink3      = Color(0xFF8E8E93);
  static const ink4      = Color(0xFFC7C7CC);
  static const hairline  = Color(0x1F3C3C43);
  static const forest    = Color(0xFF0F4F45);
  static const forestSoft= Color(0xFFE8F0EC);
  static const blush     = Color(0xFFF2E8E3);
  static const amber     = Color(0xFFF5A623);
  static const cream     = Color(0xFFFAF7F2);
  static const cardWhite = Color(0xFFFFFFFF);
}

TextStyle serif({
  double fontSize = 16,
  FontWeight fontWeight = FontWeight.w400,
  bool italic = false,
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  return GoogleFonts.cormorantGaramond(
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

class AppMark extends StatelessWidget {
  final double size;
  const AppMark({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: T.forest,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Center(
        child: Text(
          'S',
          style: serif(
            fontSize: size * 0.55,
            fontWeight: FontWeight.w600,
            italic: true,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
