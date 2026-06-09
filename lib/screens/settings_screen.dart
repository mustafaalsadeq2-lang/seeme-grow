import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../services/notification_service.dart';
import '../storage/local_storage_service.dart';
import '../utils/app_tokens.dart';
import 'auth/sign_in_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkMode             = false;
  bool _isPremium            = false;
  bool _isReviewerSignedIn   = false;
  String? _reviewerEmail;
  StreamSubscription<AuthState>? _authSub;

  SupabaseClient get _supabase => Supabase.instance.client;

  // ── Computed getters ──────────────────────────────────────────────────────

  bool get _isSignedIn =>
      _supabase.auth.currentSession != null || _isReviewerSignedIn;

  String? get _userEmail =>
      _supabase.auth.currentUser?.email ?? _reviewerEmail;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadAllFlags();
    _setupAuthStream();
    // Mirror current theme mode into local state.
    _darkMode = themeNotifier.value == ThemeMode.dark;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  // ── Flags ─────────────────────────────────────────────────────────────────

  Future<void> _loadAllFlags() async {
    final prefs = await SharedPreferences.getInstance();

    final isReviewer        = prefs.getBool('is_reviewer_signed_in') ?? false;
    final reviewerEmail     = prefs.getString('reviewer_email');
    final notificationsOn   = await NotificationService.isEnabled();

    // Step 1 — prefs (instant): update reviewer flag + notifications immediately
    // so the UI renders correctly before the slower network call below.
    if (!mounted) return;
    setState(() {
      _isReviewerSignedIn  = isReviewer;
      _reviewerEmail       = reviewerEmail;
      _notificationsEnabled = notificationsOn;
    });

    // Step 2 — network (slow): check premium status without blocking Step 1.
    // RevenueCatService.isPremium() goes here once paywall is restored.
    // For now we read a local flag set by the paywall flow.
    final premium = prefs.getBool('is_premium') ?? false;
    if (!mounted) return;
    setState(() => _isPremium = premium);
  }

  void _setupAuthStream() {
    // Never blindly reset _isReviewerSignedIn in the stream handler —
    // always reload from prefs so the reviewer flag survives Supabase events.
    _authSub = _supabase.auth.onAuthStateChange.listen((_) {
      if (mounted) _loadAllFlags();
    });
  }

  // ── Toggles ───────────────────────────────────────────────────────────────

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await NotificationService.setEnabled(value);
    if (value) {
      await NotificationService.scheduleAll();
    } else {
      await NotificationService.cancelAll();
    }
  }

  void _toggleDarkMode(bool value) {
    setState(() => _darkMode = value);
    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Do not clear local data on logout. Current production behavior keeps
    // local children/photos because cloud sync is not yet a full upload path.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest_mode', true);
    await prefs.setBool('is_reviewer_signed_in', false);
    await prefs.remove('reviewer_email');
    await prefs.remove('last_user_id');
    await prefs.remove('_lastAuthUserId');

    if (_isReviewerSignedIn) {
      // Reviewer has no real Supabase session — just navigate back.
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      try {
        await _supabase.auth.signOut();
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── URL launcher ──────────────────────────────────────────────────────────

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open $url'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: serif(fontSize: 18, fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // ── Account card ────────────────────────────────────────────────
          _buildAccountCard(),
          const SizedBox(height: 24),

          // ── Preferences ─────────────────────────────────────────────────
          _sectionLabel('PREFERENCES'),
          const SizedBox(height: 8),
          _buildSwitchRow(
            icon: Icons.notifications_outlined,
            title: 'Birthday Reminders',
            subtitle: 'Get notified before birthdays',
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
          const SizedBox(height: 10),
          _buildSwitchRow(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: 'Switch to dark theme',
            value: _darkMode,
            onChanged: (v) => _toggleDarkMode(v),
          ),
          const SizedBox(height: 24),

          // ── Legal ────────────────────────────────────────────────────────
          _sectionLabel('LEGAL'),
          const SizedBox(height: 8),
          _buildTapRow(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _launchUrl(
              'https://mustafaalsadeq2-lang.github.io/seeme-grow/privacy_policy.html',
            ),
          ),
          const SizedBox(height: 10),
          _buildTapRow(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () => _launchUrl(
              'https://mustafaalsadeq2-lang.github.io/seeme-grow/terms_of_service.html',
            ),
          ),
          const SizedBox(height: 10),
          _buildTapRow(
            icon: Icons.support_agent_outlined,
            title: 'Support',
            onTap: () => _launchUrl('mailto:support@seemegrow.app'),
          ),
          const SizedBox(height: 10),
          _buildTapRow(
            icon: Icons.favorite_outline,
            title: 'About SeeMeGrow',
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'SeeMeGrow',
              applicationVersion: '1.3.0',
              applicationLegalese:
                  "Crafted with care to preserve life's most precious moments.",
            ),
          ),
          const SizedBox(height: 24),

          // ── Account actions ──────────────────────────────────────────────
          if (_isSignedIn) ...[
            _sectionLabel('ACCOUNT'),
            const SizedBox(height: 8),
            _buildTapRow(
              icon: Icons.logout,
              title: 'Logout',
              destructive: true,
              onTap: _handleLogout,
            ),
            const SizedBox(height: 10),
            _buildTapRow(
              icon: Icons.delete_outline,
              title: 'Delete Account',
              destructive: true,
              onTap: _confirmDeleteAccount,
            ),
          ] else ...[
            _sectionLabel('ACCOUNT'),
            const SizedBox(height: 8),
            _buildTapRow(
              icon: Icons.login,
              title: 'Sign In',
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                  (route) => false,
                );
              },
            ),
          ],

          // ── Version ──────────────────────────────────────────────────────
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Text(
                  'SeeMeGrow',
                  style: serif(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: T.ink3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Version 1.3.0',
                  style: TextStyle(fontSize: 12, color: T.ink3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Account card (3 states) ───────────────────────────────────────────────

  Widget _buildAccountCard() {
    if (!_isSignedIn) {
      return _buildGuestCard();
    }
    if (_isPremium) {
      return _buildProCard();
    }
    return _buildFreeCard();
  }

  Widget _buildGuestCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade200,
            child: const Icon(Icons.person, color: T.ink3, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Guest Mode',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: T.ink,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Sign in to sync across devices',
                  style: TextStyle(fontSize: 13, color: T.ink3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SignInScreen()),
                (route) => false,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: T.forest,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Sign In',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeCard() {
    final email   = _userEmail ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: T.forest,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: T.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: T.forestSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Free',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: T.forest,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              // Navigate to PaywallScreen when it is restored.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Paywall coming soon.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: T.forest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Upgrade to Pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProCard() {
    final email   = _userEmail ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: T.forest,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: T.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Pro ✦',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9A7500),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Delete account ────────────────────────────────────────────────────────

  Future<void> _confirmDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all data. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await LocalStorageService.clearAll();
      await _supabase.auth.admin.deleteUser(_supabase.auth.currentUser!.id);
      await _supabase.auth.signOut();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Shared row widgets ───────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: T.ink3,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _cardDecor(),
      child: Row(
        children: [
          Icon(icon, color: T.forest, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: T.ink,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: T.ink3),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: T.forest,
          ),
        ],
      ),
    );
  }

  Widget _buildTapRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final color = destructive ? Colors.red : T.ink;
    final iconColor = destructive ? Colors.red : T.forest;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: _cardDecor(),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: T.ink4, size: 20),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecor() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: T.hairline),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
