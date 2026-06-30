import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../home_screen.dart';
import '../onboarding_screen.dart';
import 'sign_in_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _checkOnboardingCompleted() async {
    debugPrint('🔐 [AuthGate] Checking onboarding status...');
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboarding_completed') ?? false;
    debugPrint('🔐 [AuthGate] Onboarding completed: $completed');
    return completed;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔐 [AuthGate] build() called');

    return Scaffold(
      body: FutureBuilder<bool>(
        future: _checkOnboardingCompleted(),
        builder: (context, onboardingSnapshot) {
          debugPrint('🔐 [AuthGate] FutureBuilder state: ${onboardingSnapshot.connectionState}');

          if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
            debugPrint('🔐 [AuthGate] Showing loading (onboarding check)');
            return const Center(child: CircularProgressIndicator());
          }

          if (onboardingSnapshot.hasError) {
            debugPrint('❌ [AuthGate] Onboarding error: ${onboardingSnapshot.error}');
            return Center(child: Text('Error: ${onboardingSnapshot.error}'));
          }

          final onboardingCompleted = onboardingSnapshot.data ?? false;

          if (!onboardingCompleted) {
            debugPrint('🔐 [AuthGate] Showing OnboardingScreen');
            return const OnboardingScreen();
          }

          debugPrint('🔐 [AuthGate] Checking auth state...');
          return StreamBuilder<AuthState>(
            stream: Supabase.instance.client.auth.onAuthStateChange,
            builder: (context, snapshot) {
              debugPrint('🔐 [AuthGate] StreamBuilder state: ${snapshot.connectionState}');

              if (snapshot.connectionState == ConnectionState.waiting) {
                debugPrint('🔐 [AuthGate] Showing loading (auth check)');
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                debugPrint('❌ [AuthGate] Auth error: ${snapshot.error}');
                return Center(child: Text('Auth Error: ${snapshot.error}'));
              }

              final session = snapshot.data?.session;
              debugPrint('🔐 [AuthGate] Session: ${session != null ? "exists" : "null"}');

              if (session == null) {
                debugPrint('🔐 [AuthGate] Showing SignInScreen');
                return const SignInScreen();
              }

              debugPrint('🔐 [AuthGate] Showing HomeScreen');
              return const HomeScreen();
            },
          );
        },
      ),
    );
  }
}
