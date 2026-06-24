import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seeme_grow_clean/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/child.dart';
import '../../services/auth_service.dart';
import '../../storage/local_storage_service.dart';
import '../home_screen.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;

  const VerifyCodeScreen({super.key, required this.email});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _codeController = TextEditingController();
  final _focusNode      = FocusNode();
  bool _loading         = false;
  int  _resendCountdown = 60;
  Timer? _timer;

  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(Supabase.instance.client);
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) timer.cancel();
      });
    });
  }

  // ── OTP verification ──────────────────────────────────────────────────────

  Future<void> _verify() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterCode)),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await _authService.verifyOtp(email: widget.email, code: code);

      final user = Supabase.instance.client.auth.currentUser;
      debugPrint('✅ [Verify] OTP verified. user=${user?.email} id=${user?.id}');

      if (!mounted) return;

      await _handleGuestDataOnLogin(userId: user?.id, email: user?.email);

    } catch (e) {
      if (!mounted) return;
      final l10nErr = AppLocalizations.of(context)!;
      final error   = e.toString().toLowerCase();
      final String message;
      if (error.contains('invalid') || error.contains('token')) {
        message = l10nErr.invalidCode;
      } else if (error.contains('expired')) {
        message = l10nErr.codeExpired;
      } else {
        message = l10nErr.verificationFailed;
      }
      _codeController.clear();
      _focusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Guest data migration ──────────────────────────────────────────────────

  Future<void> _handleGuestDataOnLogin({
    required String? userId,
    required String? email,
  }) async {
    if (userId == null) {
      _navigateToHome();
      return;
    }

    // Load guest children BEFORE any dialog, so we know what to clean up
    // in case the "Start Fresh" path needs to remove cloud records that were
    // uploaded during the brief window after OTP verification.
    final allChildren   = await LocalStorageService.loadChildren();
    final guestChildren = allChildren.where((c) => c.userId == null).toList();
    final guestLocalIds = guestChildren.map((c) => c.localId).toList();

    debugPrint('🔐 [Verify] Guest data check: ${guestChildren.length} guest children found');

    // ── Apple Review bypass: clear automatically, no dialog ────────────────
    if (email == 'seemegrow.review@gmail.com') {
      debugPrint('✅ [Verify] Review email — clearing guest data for review login');
      await LocalStorageService.clearAll();
      debugPrint('✅ [Verify] Guest data cleared successfully');
      await _persistAuthState(userId);
      if (mounted) {
        debugPrint('✅ [Verify] Navigating to home (review mode)');
        _navigateToHome();
      }
      return;
    }

    // ── No guest data: proceed directly ────────────────────────────────────
    if (guestChildren.isEmpty) {
      debugPrint('🔐 [Verify] No guest data — proceeding to Home');
      await _persistAuthState(userId);
      if (mounted) _navigateToHome();
      return;
    }

    // ── Guest data exists: ask the user ────────────────────────────────────
    debugPrint(
      '🔐 [Verify] ${guestChildren.length} guest children detected — showing dialog',
    );

    if (!mounted) return;

    final keepData = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Keep your local memories?'),
        content: const Text(
          'You can keep the memories saved on this device with this '
          'account, or start fresh.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Start Fresh'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keep'),
          ),
        ],
      ),
    );

    if (keepData == true) {
      // ── Keep & Sync ───────────────────────────────────────────────────────
      debugPrint('✅ [Verify] Keep & Sync selected — migrating ${guestChildren.length} children');
      final migrated = guestChildren
          .map((c) => c.copyWith(userId: userId, syncState: SyncState.pending))
          .toList();
      final nonGuest = allChildren.where((c) => c.userId != null).toList();
      await LocalStorageService.saveChildren([...nonGuest, ...migrated]);
      debugPrint('✅ [Verify] ${migrated.length} children migrated to user $userId');
    } else {
      // ── Start Fresh ───────────────────────────────────────────────────────
      debugPrint('🗑️ [Verify] Start Fresh selected');

      // 1. Clear local storage first.
      await LocalStorageService.clearAll();
      debugPrint('✅ [Verify] Local data cleared');

      // 2. Delete any cloud records that were uploaded during the brief window
      //    between OTP verification and this dialog. The HomeScreen auth listener
      //    may have triggered a sync that uploaded guest children to Supabase.
      //    We target only the specific guest localIds to avoid deleting existing
      //    account data the user had before this login.
      if (guestLocalIds.isNotEmpty) {
        debugPrint('🗑️ [Verify] Removing ${guestLocalIds.length} guest records from cloud...');
        try {
          for (final localId in guestLocalIds) {
            await Supabase.instance.client
                .from('children')
                .delete()
                .eq('user_id', userId)
                .eq('local_id', localId);
          }
          debugPrint('✅ [Verify] Cloud guest records removed');
        } catch (e) {
          // Non-fatal: if the children were never uploaded, delete is a no-op.
          debugPrint('⚠️ [Verify] Cloud cleanup failed (may be expected): $e');
        }
      }

      debugPrint('🔐 [Verify] Home children state cleared (fresh navigation)');
      debugPrint('🔄 [Verify] Reloading cloud data only after Start Fresh');
    }

    await _persistAuthState(userId);
    if (mounted) _navigateToHome();
  }

  // ── Persist auth state ────────────────────────────────────────────────────

  Future<void> _persistAuthState(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest_mode', false);
    await prefs.setBool('is_reviewer_signed_in', false);
    await prefs.remove('reviewer_email');
    await prefs.setString('last_user_id', userId);
    await prefs.setString('_lastAuthUserId', userId);
    debugPrint('✅ [Verify] Auth state persisted: userId=$userId');
  }

  // ── Navigate ──────────────────────────────────────────────────────────────

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  // ── Resend ────────────────────────────────────────────────────────────────

  Future<void> _resendCode() async {
    try {
      await _authService.sendOtp(widget.email);
      if (!mounted) return;
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.newCodeSent),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.resendFailed(e.toString())),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onCodeChanged(String value) {
    if (value.length == 6) _verify();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n      = AppLocalizations.of(context)!;
    final canResend = _resendCountdown <= 0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.verifyEmail)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email_outlined, size: 48,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(l10n.enterCodeSentTo,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              widget.email,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            AutofillGroup(
              child: TextField(
                controller: _codeController,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: 12),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: _onCodeChanged,
                decoration: const InputDecoration(
                  hintText: '------',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _verify,
                child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.verifyAndContinue),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: canResend ? _resendCode : null,
              child: Text(canResend
                  ? l10n.resendCode
                  : l10n.resendCodeIn(_resendCountdown.toString())),
            ),
          ],
        ),
      ),
    );
  }
}
