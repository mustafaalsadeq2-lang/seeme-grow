import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
            subtitle: 'Keep your child’s memories safe',
            trailing: const Text(
              'Coming Soon',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
            onTap: null, // disabled for now
          ),

          const SizedBox(height: 12),

          // 🔹 About
          _SettingsCard(
            icon: Icons.favorite_outline,
            title: 'About SeeMeGrow',
            subtitle:
                'A private space to capture and relive childhood memories',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'SeeMeGrow',
                applicationVersion: '1.1.0',
                applicationLegalese:
                    'Crafted with care to preserve life’s most precious moments.',
              );
            },
          ),

          const SizedBox(height: 40),

          // 🔹 Version (footer)
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
        enabled: onTap != null,
        onTap: onTap,
        leading: Icon(
          icon,
          color: Colors.purple,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
        trailing: trailing ??
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
      ),
    );
  }
}
