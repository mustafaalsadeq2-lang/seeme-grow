import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../children_dashboard_screen.dart';
import 'sign_in_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (session == null) {
          return SignInScreen(); // ❌ no const
        }

        return const ChildrenDashboardScreen();
      },
    );
  }
}
