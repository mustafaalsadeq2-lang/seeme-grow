import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../home_screen.dart';
import '../onboarding_screen.dart';
import 'sign_in_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _checkOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkOnboardingCompleted(),
      builder: (context, onboardingSnapshot) {
        // Show loading while checking onboarding status
        if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final onboardingCompleted = onboardingSnapshot.data ?? false;

        // If onboarding not completed, show onboarding screen
        if (!onboardingCompleted) {
          return const OnboardingScreen();
        }

        // Otherwise, proceed with auth check
        return StreamBuilder<AuthState>(
          stream: Supabase.instance.client.auth.onAuthStateChange,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final session = snapshot.data?.session;

            if (session == null) {
              return const SignInScreen();
            }

            return const HomeScreen();
          },
        );
      },
    );
  }
}