import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../export/export_service.dart';
import '../models/child.dart';

class ExportScreen extends StatefulWidget {
  final Child child;

  const ExportScreen({super.key, required this.child});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _exporting = false;
  File? _poster;
  File? _video;
  String? _error;

  Future<void> _export() async {
    setState(() {
      _exporting = true;
      _error = null;
      _poster = null;
      _video = null;
    });

    try {
      final result = await ExportService.exportAll(widget.child);
      setState(() {
        _poster = result.posterImage;
        _video = result.videoFile;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _exporting = false;
      });
    }
  }

  Future<void> _shareFiles() async {
    final files = <XFile>[];
    if (_poster != null) files.add(XFile(_poster!.path));
    if (_video != null) files.add(XFile(_video!.path));

    if (files.isEmpty) return;

    await Share.shareXFiles(
      files,
      text: 'My child timeline • SeeMeGrow',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Timeline'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.child.name,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a beautiful timeline poster and a real video you can share.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            if (_exporting)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),

            if (!_exporting && _poster == null && _video == null)
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Create Timeline'),
                  onPressed: _export,
                ),
              ),

            if (!_exporting && (_poster != null || _video != null)) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  onPressed: _shareFiles,
                ),
              ),
            ],

            const Spacer(),
            const Text(
              'Tip: Tap Share to save to your gallery or send to family.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
