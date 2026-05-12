import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../home_screen.dart';
import '../onboarding_screen.dart';
import 'sign_in_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _onboardingCompleted = false;
  bool _loading = true;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboarding_completed') ?? false;

    if (!mounted) return;
    setState(() {
      _onboardingCompleted = completed;
      _loading = false;
    });

    // Only trigger a repaint on auth events — no data migration here.
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_onboardingCompleted) {
      return const OnboardingScreen();
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      return const SignInScreen();
    }

    return const HomeScreen();
  }
}
