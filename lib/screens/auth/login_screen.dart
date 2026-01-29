import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  bool _sending = false;
  bool _verifying = false;
  bool _codeSent = false;

  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String get _email => _emailController.text.trim();

  bool get _emailLooksValid =>
      _email.contains('@') && _email.contains('.') && _email.length >= 6;

  Future<void> _sendCode() async {
    setState(() {
      _error = null;
      _sending = true;
    });

    try {
      final auth = ref.read(authServiceProvider);
      await auth.sendEmailOtp(_email);

      if (!mounted) return;
      setState(() {
        _codeSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code sent ✅ Check your email')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to send code: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _verifyCode() async {
    setState(() {
      _error = null;
      _verifying = true;
    });

    try {
      final auth = ref.read(authServiceProvider);
      await auth.verifyEmailOtp(
        email: _email,
        token: _codeController.text,
      );

      // AuthGate will auto-navigate to HomeScreen after session updates
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Invalid code or expired. Try again.\n$e';
      });
    } finally {
      if (mounted) {
        setState(() => _verifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSend = !_sending && _emailLooksValid;
    final canVerify = !_verifying &&
        _codeSent &&
        _codeController.text.trim().length >= 4;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in'),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              'Welcome to SeeMeGrow',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your email and we’ll send you a one-time code.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
                setState(() {}); // refresh button state
              },
            ),
            const SizedBox(height: 12),

            if (_codeSent) ...[
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Code',
                  hintText: 'Enter the code from your email',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                  setState(() {});
                },
              ),
              const SizedBox(height: 12),
            ],

            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.35)),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: canSend ? _sendCode : null,
                child: _sending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_codeSent ? 'Resend Code' : 'Send Code'),
              ),
            ),

            const SizedBox(height: 12),

            if (_codeSent)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: canVerify ? _verifyCode : null,
                  child: _verifying
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify & Continue'),
                ),
              ),

            const Spacer(),

            Text(
              'We’ll add Apple/Google sign-in later for the best App Store experience.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
