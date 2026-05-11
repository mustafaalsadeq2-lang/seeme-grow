import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:seeme_grow_clean/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../storage/local_storage_service.dart';
import '../../utils/app_tokens.dart';
import '../home_screen.dart';
import 'verify_code_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  String? _emailError;

  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(Supabase.instance.client);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  // ── Validation ──────────────────────────────────────────────────────────────

  static const _blockedDomains = {
    'test.com', 'example.com', 'example.org', 'example.net',
    'fake.com', 'abc.com', 'mailinator.com', 'guerrillamail.com',
    'temp.com', 'dummy.com', 'yopmail.com', 'trashmail.com',
  };

  static const _blockedEmails = {
    'fake@gmail.com',
    'test@gmail.com',
    'abc@gmail.com',
    'user@gmail.com',
  };

  String? _validateEmail(String email) {
    if (email.isEmpty) return null;

    final lower = email.toLowerCase();
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');

    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address.';
    }

    final domain = lower.split('@').last;
    if (_blockedDomains.contains(domain)) {
      return 'Please enter a valid email address.';
    }

    if (_blockedEmails.contains(lower)) {
      return 'Please enter a valid email address.';
    }

    return null;
  }

  // ── Cooldown ────────────────────────────────────────────────────────────────

  void _startCooldown() {
    _cooldownSeconds = 60;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) timer.cancel();
      });
    });
  }

  bool get _canSend => !_loading && _cooldownSeconds == 0;

  // ── Guest mode ──────────────────────────────────────────────────────────────

  Future<void> _continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest_mode', true);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  // ── Send OTP ────────────────────────────────────────────────────────────────

  Future<void> _sendCode() async {
    if (!_canSend) return;

    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterEmail), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final validationError = _validateEmail(email);
    if (validationError != null) {
      setState(() => _emailError = validationError);
      return;
    }
    setState(() => _emailError = null);

    // Apple Review bypass — no real Supabase session is created.
    if (email == 'seemegrow.review@gmail.com') {
      debugPrint('✅ [SignIn] Apple Review bypass for: $email');
      debugPrint('🗑️ [SignIn] Clearing guest data for review login');

      await LocalStorageService.clearAll();
      debugPrint('✅ [SignIn] Guest data cleared successfully');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest_mode', false);
      await prefs.setBool('is_reviewer_signed_in', true);
      await prefs.setString('reviewer_email', email);
      await prefs.setBool('onboarding_completed', true);
      await prefs.remove('last_user_id');
      await prefs.remove('_lastAuthUserId');
      if (!mounted) return;

      debugPrint('✅ [SignIn] Navigating to home (review mode)');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
      return;
    }

    if (kDebugMode) {
      debugPrint('📧 [SignIn] Sending OTP to: $email');
    }

    setState(() => _loading = true);

    try {
      await _authService.sendOtp(email);

      if (!mounted) return;

      debugPrint('✅ [SignIn] OTP sent successfully to: $email');

      _startCooldown();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.codeSent),
          backgroundColor: T.forest,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VerifyCodeScreen(email: email)),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ [SignIn] OTP send failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.sendError(e.toString())),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final inCooldown = _cooldownSeconds > 0;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  const AppMark(size: 40),
                  const SizedBox(height: 28),

                  // Headline
                  Text.rich(
                    TextSpan(
                      style: serif(fontSize: 40, height: 1.05, letterSpacing: -0.6),
                      children: [
                        const TextSpan(text: 'Welcome '),
                        TextSpan(
                          text: 'back.',
                          style: serif(fontSize: 40, italic: true, color: T.forest, height: 1.05),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sign in to keep their story safe across devices.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: T.ink3, height: 1.5),
                  ),

                  const SizedBox(height: 44),

                  // Email field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _emailError != null ? Colors.red : T.hairline,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 3),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autocorrect: false,
                          onSubmitted: (_) => _sendCode(),
                          onChanged: (_) {
                            if (_emailError != null) setState(() => _emailError = null);
                          },
                          style: const TextStyle(fontSize: 16, color: T.ink),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            labelText: l10n.emailLabel,
                            labelStyle: const TextStyle(fontSize: 11, letterSpacing: 1.2, color: T.ink3),
                            floatingLabelStyle: const TextStyle(fontSize: 11, letterSpacing: 1.2, color: T.ink3),
                          ),
                        ),
                      ),
                      if (_emailError != null) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            _emailError!,
                            style: const TextStyle(fontSize: 12, color: Colors.red),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Send / cooldown button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _canSend ? _sendCode : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: T.ink,
                        disabledBackgroundColor: T.ink4,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              inCooldown
                                  ? 'You can request another code in ${_cooldownSeconds}s'
                                  : l10n.sendVerificationCode,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Row(
                      children: [
                        const Expanded(child: Divider(color: T.hairline)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or', style: serif(fontSize: 14, italic: true, color: T.ink3)),
                        ),
                        const Expanded(child: Divider(color: T.hairline)),
                      ],
                    ),
                  ),

                  // Continue as guest
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _continueAsGuest,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: T.hairline),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        backgroundColor: Colors.white,
                        foregroundColor: T.ink,
                      ),
                      child: Text(
                        l10n.continueAsGuest,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // "Just exploring?" footer
            Positioned(
              bottom: 36, left: 0, right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _continueAsGuest,
                  child: Text.rich(
                    TextSpan(
                      text: 'Just exploring? ',
                      style: const TextStyle(fontSize: 13, color: T.ink3),
                      children: [
                        TextSpan(
                          text: 'Continue as guest',
                          style: const TextStyle(color: T.forest, fontWeight: FontWeight.w600),
                        ),
                      ],
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
}
