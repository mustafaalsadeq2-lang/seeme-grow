import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/child.dart';
import '../storage/local_storage_service.dart';

class YearDetailScreen extends StatefulWidget {
  final Child child;
  final int year;

  const YearDetailScreen({
    super.key,
    required this.child,
    required this.year,
  });

  @override
  State<YearDetailScreen> createState() => _YearDetailScreenState();
}

class _YearDetailScreenState extends State<YearDetailScreen>
    with SingleTickerProviderStateMixin {
  String? _imagePath;
  bool _loading = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _loadFromStorage();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadFromStorage() async {
    final children = await LocalStorageService.loadChildren();
    final freshChild = children.firstWhere(
      (c) => c.localId == widget.child.localId,
    );

    if (!mounted) return;

    setState(() {
      _imagePath = freshChild.yearPhotos[widget.year];
    });

    _fadeController.forward(from: 0);
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _showPhotoOptions() async {
    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF26A69A)),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF7E57C2)),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.close, color: Colors.grey.shade600),
                title: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (result == null) return;

    await _pickPhoto(result);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (pickedFile == null) return;

      setState(() => _loading = true);

      final appDir = await getApplicationDocumentsDirectory();
      final childDir = Directory('${appDir.path}/${widget.child.localId}');
      if (!await childDir.exists()) {
        await childDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = '${childDir.path}/year_${widget.year}_$timestamp.jpg';

      await File(pickedFile.path).copy(newPath);

      final children = await LocalStorageService.loadChildren();
      final index = children.indexWhere(
        (c) => c.localId == widget.child.localId,
      );

      final updatedChild = children[index];
      updatedChild.yearPhotos[widget.year] = newPath;

      children[index] = updatedChild;
      await LocalStorageService.saveChildren(children);

      HapticFeedback.mediumImpact();

      await _loadFromStorage();

      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '✨ Memory saved',
            textAlign: TextAlign.center,
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to capture photo: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }

  String _ageText() {
    if (widget.year == 0) return 'Newborn';

    final birth = widget.child.birthDate;
    final target =
        DateTime(birth.year + widget.year, birth.month, birth.day);

    int y = target.year - birth.year;
    int m = target.month - birth.month;
    int d = target.day - birth.day;

    if (d < 0) {
      m--;
      d += DateTime(target.year, target.month, 0).day;
    }
    if (m < 0) {
      y--;
      m += 12;
    }

    final parts = <String>[];
    if (y > 0) parts.add('$y years');
    if (m > 0) parts.add('$m months');
    if (d > 0) parts.add('$d days');

    return parts.join(' · ');
  }

  Widget _buildImage() {
    if (_imagePath == null || _imagePath!.isEmpty) {
      return const Center(
        child: Text(
          'No photo added yet',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final file = File(_imagePath!);

    if (!file.existsSync()) {
      return const Center(
        child: Text(
          'Image not found',
          style: TextStyle(color: Colors.redAccent),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Image.file(
        file,
        fit: BoxFit.contain,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final yearLabel = widget.year == 0 ? 'Birth' : 'Year ${widget.year}';
    final calendarYear =
        widget.child.birthDate.year + widget.year;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.child.name} · $yearLabel'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Hero(
                          tag:
                              'year_photo_${widget.child.localId}_${widget.year}',
                          child: Container(
                            color: Colors.black,
                            child: Center(child: _buildImage()),
                          ),
                        ),
                      ),
                      if (_loading)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black54,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.child.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _ageText(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              calendarYear.toString(),
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Add / Change Photo'),
                  onPressed: _loading ? null : _showPhotoOptions,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
