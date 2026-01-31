import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final enabled = await NotificationService.isEnabled();
    if (!mounted) return;
    setState(() => _notificationsEnabled = enabled);
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await NotificationService.setEnabled(value);
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await Supabase.instance.client.auth.signOut();

      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔹 Backup & Restore
          _SettingsCard(
            icon: Icons.cloud_outlined,
            title: 'Backup & Restore',
            subtitle: "Keep your child's memories safe", // ✅ double quotes
            trailing: const Text(
              'Coming Soon',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
            onTap: null,
          ),

          const SizedBox(height: 12),

          // 🔹 Notifications
          _SettingsCard(
            icon: Icons.notifications_outlined,
            title: 'Birthday Reminders',
            subtitle: "Get notified before your child's birthday",
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
            ),
            onTap: null,
          ),

          const SizedBox(height: 12),

          // 🔹 About
          _SettingsCard(
            icon: Icons.favorite_outline,
            title: 'About SeeMeGrow',
            subtitle: 'A private space to capture and relive childhood memories',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'SeeMeGrow',
                applicationVersion: '1.1.0',
                applicationLegalese:
                    "Crafted with care to preserve life's most precious moments.", // ✅ double quotes
              );
            },
          ),

          const SizedBox(height: 12),

          // 🔹 Logout
          _SettingsCard(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            trailing: const Icon(
              Icons.chevron_right,
              color: Colors.red,
            ),
            onTap: () => _handleLogout(context),
          ),

          const SizedBox(height: 40),

          // 🔹 Version
          const Center(
            child: Column(
              children: [
                Text(
                  'SeeMeGrow',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Version 1.1.0',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 🔹 Reusable Settings Card
class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        enabled: onTap != null || trailing is Switch,
        onTap: onTap,
        leading: Icon(
          icon,
          color: (onTap == null && trailing is! Switch)
              ? Colors.grey
              : (icon == Icons.logout ? Colors.red : Colors.purple),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: icon == Icons.logout ? Colors.red : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
        trailing: trailing ??
            Icon(
              Icons.chevron_right,
              color: onTap == null ? Colors.grey : null,
            ),
      ),
    );
  }
}