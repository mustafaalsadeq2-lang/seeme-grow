import 'package:flutter/material.dart';

import '../models/child.dart';
import '../storage/local_storage_service.dart';

class EditChildScreen extends StatefulWidget {
  final Child child;

  const EditChildScreen({
    super.key,
    required this.child,
  });

  @override
  State<EditChildScreen> createState() => _EditChildScreenState();
}

class _EditChildScreenState extends State<EditChildScreen> {
  late TextEditingController _nameController;
  DateTime? _birthDate;
  bool _saving = false;

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty &&
      _birthDate != null &&
      !_saving;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.child.name);
    _birthDate = widget.child.birthDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_canSave) return;

    try {
      setState(() => _saving = true);

      final updatedChild = widget.child.copyWith(
        name: _nameController.text.trim(),
        birthDate: _birthDate!,
        updatedAt: DateTime.now(),
      );

      await LocalStorageService.updateChild(updatedChild);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Save error: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final birthText = _birthDate == null
        ? 'Not selected'
        : _birthDate!.toIso8601String().split('T').first;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Child')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Child name'),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickBirthDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _birthDate == null
                    ? 'Select birth date'
                    : birthText,
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _canSave ? _save : null,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
