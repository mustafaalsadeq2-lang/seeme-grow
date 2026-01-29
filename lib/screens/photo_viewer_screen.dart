import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({
    super.key,
    required this.images,
    required this.initialIndex,
    this.title,
  });

  /// List of image sources.
  /// - Mobile: file path like /var/.../image.jpg
  /// - Web: can be a URL or data:image/...;base64,...
  final List<String> images;

  final int initialIndex;
  final String? title;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _controller;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleControls,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: widget.images.length,
                  itemBuilder: (context, index) {
                    final src = widget.images[index];
                    return InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Center(child: _buildImage(src)),
                    );
                  },
                ),
              ),
            ),

            // Back control (tap to hide/show)
            Positioned(
              top: 8,
              left: 8,
              child: AnimatedOpacity(
                opacity: _showControls ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),

            if (widget.title != null)
              Positioned(
                top: 14,
                left: 56,
                right: 12,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: Text(
                      widget.title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String src) {
    final s = src.trim();

    // Support data:image/...;base64,... on ALL platforms
    if (s.startsWith('data:image/')) {
      final comma = s.indexOf(',');
      if (comma > 0 && comma < s.length - 1) {
        final b64 = s.substring(comma + 1);
        try {
          final bytes = base64Decode(b64);
          return Image.memory(bytes, fit: BoxFit.contain);
        } catch (_) {
          return _broken();
        }
      }
      return _broken();
    }

    // Web: must use network for non-data urls
    if (kIsWeb) {
      return Image.network(
        s,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _broken(),
      );
    }

    // Mobile: file path
    final file = File(s);
    return Image.file(
      file,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _broken(),
    );
  }

  Widget _broken() {
    return const Icon(Icons.broken_image_outlined, color: Colors.white70, size: 60);
  }
}
