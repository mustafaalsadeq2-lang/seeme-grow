import 'package:flutter/material.dart';
import 'package:seeme_grow_clean/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import '../models/child.dart';
import '../utils/app_tokens.dart';

class AddChildScreen extends StatefulWidget {
  final Set<String> existingNames;

  const AddChildScreen({
    super.key,
    required this.existingNames,
  });

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _nameController = TextEditingController();
  final _nameFocus      = FocusNode();

  DateTime? _birthDate;
  bool      _saving = false;
  String?   _error;

  String get _name => _nameController.text.trim();

  bool get _canSave =>
      _name.isNotEmpty && _birthDate != null && !_saving;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _nameFocus.requestFocus(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  // ── Date picker ────────────────────────────────────────────────────────────

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: T.forest),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  String get _formattedDate {
    if (_birthDate == null) return '';
    final d = _birthDate!;
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  void _save() {
    if (!_canSave) return;

    final l10n = AppLocalizations.of(context)!;
    final normalized = _name.toLowerCase();
    if (widget.existingNames.contains(normalized)) {
      setState(() => _error = l10n.nameAlreadyExists);
      return;
    }

    setState(() { _saving = true; _error = null; });

    final child = Child(
      localId  : const Uuid().v4(),
      name     : _name,
      birthDate: _birthDate!,
    );

    Navigator.pop(context, child);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.newChildTitle,
          style: serif(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Builder(builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Serif heading ──────────────────────────────────────
                      Text(
                        l10n.aNewChapter,
                        style: serif(
                          fontSize: 36,
                          fontWeight: FontWeight.w400,
                          height: 1.1,
                          color: T.ink,
                        ),
                      ),
                      Text(
                        l10n.begins,
                        style: serif(
                          fontSize: 36,
                          fontWeight: FontWeight.w600,
                          italic: true,
                          color: T.forest,
                          height: 1.1,
                        ),
                      ),

                      const SizedBox(height: 44),

                      // ── Name field (borderless) ────────────────────────────
                      Text(
                        l10n.nameLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: T.ink3,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        focusNode: _nameFocus,
                        textCapitalization: TextCapitalization.words,
                        style: serif(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: T.ink,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: l10n.childNameHint,
                          hintStyle: serif(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: T.ink4,
                          ),
                          errorText: _error,
                          errorStyle: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                        onChanged: (_) {
                          if (_error != null) setState(() => _error = null);
                        },
                        onSubmitted: (_) => _pickBirthDate(),
                      ),

                      const SizedBox(height: 32),

                      // ── Birth date (underline field) ───────────────────────
                      Text(
                        l10n.birthDateLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: T.ink3,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickBirthDate,
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: T.hairline, width: 1.5),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _birthDate == null
                                      ? l10n.selectBirthDate
                                      : _formattedDate,
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: _birthDate == null ? T.ink3 : T.ink,
                                    fontWeight: _birthDate == null
                                        ? FontWeight.w400
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: _birthDate == null ? T.ink3 : T.forest,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Timeline preview chip ───────────────────────────────
                      if (_name.isNotEmpty || _birthDate != null)
                        AnimatedOpacity(
                          opacity: (_name.isNotEmpty && _birthDate != null) ? 1.0 : 0.4,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: T.forestSoft,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: T.forest.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  size: 13,
                                  color: T.forest,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _name.isNotEmpty
                                      ? l10n.beginStory(_name)
                                      : l10n.beginTheirStory,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: T.forest,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── CTA button ─────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canSave ? _save : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: T.ink,
                    disabledBackgroundColor: T.ink4,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _name.isNotEmpty
                              ? l10n.beginStory(_name)
                              : l10n.beginTheirStory,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
        }),
      ),
    );
  }
}
