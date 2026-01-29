import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/child.dart';

class AddChildScreen extends StatefulWidget {
  /// أسماء الأطفال الحالية (lowercase)
  final Set<String> existingNames;

  const AddChildScreen({
    super.key,
    required this.existingNames,
  });

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final TextEditingController _nameController = TextEditingController();
  DateTime? _birthDate;
  bool _saving = false;
  String? _error;

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty &&
      _birthDate != null &&
      !_saving;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? now,
      firstDate: DateTime(1990),
      lastDate: now,
    );

    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  void _save() {
    if (!_canSave) return;

    final name = _nameController.text.trim();
    final normalized = name.toLowerCase();

    if (widget.existingNames.contains(normalized)) {
      setState(() => _error = 'This name already exists');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final child = Child(
      localId: const Uuid().v4(),
      name: name,
      birthDate: _birthDate!,
    );

    Navigator.pop(context, child);
  }

  @override
  Widget build(BuildContext context) {
    final birthText = _birthDate == null
        ? 'Not selected'
        : _birthDate!.toIso8601String().split('T').first;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Child')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Child name'),
              onChanged: (_) => setState(() => _error = null),
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
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
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
