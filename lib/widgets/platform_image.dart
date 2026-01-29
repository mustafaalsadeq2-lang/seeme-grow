import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PlatformImage extends StatelessWidget {
  final String path;
  final BoxFit fit;

  const PlatformImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(path, fit: fit);
    } else {
      return Image.file(File(path), fit: fit);
    }
  }
}
