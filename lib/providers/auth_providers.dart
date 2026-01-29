import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

/// 🔹 Supabase client (single source of truth)
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// 🔹 Auth service wrapper
final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthService(client);
});

/// 🔹 Auth state changes stream
/// Used فقط لإعادة بناء AuthGate عند أي تغيير (login / logout / refresh)
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.onAuthStateChange;
});

/// 🔹 Current session provider
/// مصدر الحقيقة النهائي لتحديد:
/// - Logged in
/// - Logged out
final sessionProvider = Provider<Session?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.currentSession;
});
