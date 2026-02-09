import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get onAuthStateChange =>
      _client.auth.onAuthStateChange;

  // ---------------------------------------------------------------------------
  // Send OTP code (FORCE EMAIL OTP)
  // ---------------------------------------------------------------------------
  Future<void> sendEmailCode(String email) async {
    debugPrint('📧 Sending EMAIL OTP to $email');

    await _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true,
      emailRedirectTo: null, // 🔒 disable magic link
    );
  }

  // ---------------------------------------------------------------------------
  // Verify OTP code (EMAIL)
  // ---------------------------------------------------------------------------
  Future<void> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    debugPrint('🔐 Verifying EMAIL OTP for $email');

    final res = await _client.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.email,
    );

    if (res.session == null) {
      throw AuthException('OTP verification failed');
    }

    debugPrint('✅ User authenticated');
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
