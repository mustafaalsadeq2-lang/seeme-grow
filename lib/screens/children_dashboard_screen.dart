import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/child.dart';
import '../repositories/local_child_repository.dart';
import '../services/auth_service.dart';
import '../services/child_sync_service.dart';
import '../screens/child_page.dart';
import '../screens/auth/auth_gate.dart';
import 'add_edit_child_screen.dart';

class ChildrenDashboardScreen extends StatefulWidget {
  const ChildrenDashboardScreen({super.key});

  @override
  State<ChildrenDashboardScreen> createState() =>
      _ChildrenDashboardScreenState();
}

class _ChildrenDashboardScreenState extends State<ChildrenDashboardScreen>
    with WidgetsBindingObserver {
  final LocalChildRepository _localChildRepository =
      LocalChildRepository();

  late final ChildSyncService _syncService;

  List<Child> _children = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _syncService = ChildSyncService(
      supabase: Supabase.instance.client,
      authService: AuthService(Supabase.instance.client),
    );

    _loadChildren();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadChildren();
    }
  }

  Future<void> _loadChildren() async {
    setState(() => _loading = true);

    final children = await _localChildRepository.getAll();

    if (!mounted) return;

    setState(() {
      _children = children;
      _loading = false;
    });

    await _syncService.syncPendingChildren();
  }

  Future<void> _openEditChild(Child child) async {
    final updatedChild = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditChildScreen(child: child),
      ),
    );

    if (updatedChild != null) {
      await _loadChildren();
    }
  }

  /// ✅ Logout احترافي + إعادة توجيه واضحة
  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  String _ageText(Child child) {
    final now = DateTime.now();
    final birth = child.birthDate;

    int years = now.year - birth.year;
    int months = now.month - birth.month;
    int days = now.day - birth.day;

    if (days < 0) {
      months--;
      days += DateTime(now.year, now.month, 0).day;
    }
    if (months < 0) {
      years--;
      months += 12;
    }

    final parts = <String>[];
    if (years > 0) parts.add('$years years');
    if (months > 0) parts.add('$months months');
    if (days > 0) parts.add('$days days');

    return parts.isEmpty ? 'Newborn' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Children'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _children.isEmpty
              ? const Center(
                  child: Text(
                    'No children added yet',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _children.length,
                  itemBuilder: (context, index) {
                    final child = _children[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        title: Text(
                          child.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _ageText(child),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _openEditChild(child);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChildPage(child: child),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
