import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/child.dart';
import '../services/notification_service.dart';
import '../storage/local_storage_service.dart';
import '../utils/age_calculator.dart';
import 'add_child_screen.dart';
import 'edit_child_screen.dart';
import 'settings_screen.dart';
import 'timeline_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  List<Child> _children = [];
  bool _syncing = false;

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadChildren();
    _syncFromCloud(); // Phase 1: read-only
    _initNotifications();
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
      _syncFromCloud();
    }
  }

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------

  Future<void> _initNotifications() async {
    await NotificationService.init();
    await NotificationService.testNotification();
  }

  // ---------------------------------------------------------------------------
  // Local
  // ---------------------------------------------------------------------------

  Future<void> _loadChildren() async {
    final children = await LocalStorageService.loadChildren();

    children.sort(
      (a, b) => b.birthDate.compareTo(a.birthDate),
    );

    if (!mounted) return;
    setState(() => _children = children);
    NotificationService.scheduleAll();
  }

  // ---------------------------------------------------------------------------
  // Cloud (Phase 1 – Read only)
  // ---------------------------------------------------------------------------

  Future<void> _syncFromCloud() async {
    final user = _supabase.auth.currentUser;
    if (user == null || _syncing) return;

    setState(() => _syncing = true);

    try {
      final response = await _supabase
          .from('children')
          .select()
          .eq('user_id', user.id);

      final local = await LocalStorageService.loadChildren();
      final localIds = local.map((c) => c.localId).toSet();

      for (final row in response) {
        final cloudChild = Child.fromJson(row);

        if (!localIds.contains(cloudChild.localId)) {
          local.add(cloudChild);
        }
      }

      await LocalStorageService.saveChildren(local);
      await _loadChildren();
    } catch (_) {
      // silent fail
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  // ---------------------------------------------------------------------------
  // AUTH
  // ---------------------------------------------------------------------------

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    // AuthGate سيعيدك تلقائياً إلى LoginScreen
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  Future<void> _addChild() async {
    final existingNames =
        _children.map((c) => c.name.toLowerCase().trim()).toSet();

    final result = await Navigator.push<Child?>(
      context,
      MaterialPageRoute(
        builder: (_) => AddChildScreen(
          existingNames: existingNames,
        ),
      ),
    );

    if (result != null) {
      await LocalStorageService.addChild(result);
      await NotificationService.scheduleAll();
      _loadChildren();
    }
  }

  Future<void> _editChild(Child child) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditChildScreen(child: child),
      ),
    );

    if (changed == true) {
      _loadChildren();
    }
  }

  Future<void> _deleteChild(Child child) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove child'),
        content: Text(
          'This will permanently delete all memories for ${child.name}.\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await NotificationService.cancelForChild(child.localId);
      await LocalStorageService.deleteChild(child.localId);
      _loadChildren();
    }
  }

  // ---------------------------------------------------------------------------
  // UI helpers
  // ---------------------------------------------------------------------------

  Color _avatarColor(String localId) {
    final colors = [
      Colors.purple,
      Colors.blue,
      Colors.teal,
      Colors.indigo,
      Colors.orange,
      Colors.pink,
      Colors.green,
    ];
    return colors[localId.hashCode.abs() % colors.length];
  }

  String _initial(String name) =>
      name.isNotEmpty ? name.characters.first : '?';

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Children'),
        actions: [
          if (_syncing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.sync, size: 18),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'settings') {
                _openSettings();
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'settings',
                child: Text('Settings'),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _children.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _children.length,
              itemBuilder: (context, index) {
                final child = _children[index];
                final age =
                    AgeCalculator.currentAge(child.birthDate);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          _avatarColor(child.localId),
                      child: Text(
                        _initial(child.name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                        age.toString(),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editChild(child);
                        } else if (value == 'delete') {
                          _deleteChild(child);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: 'edit', child: Text('Edit')),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TimelineScreen(
                            childId: child.localId,
                          ),
                        ),
                      );
                      _loadChildren();
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addChild,
        icon: const Icon(Icons.add),
        label: const Text('Add Child'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.child_care, size: 88, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'No children added yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Start by adding your child to begin capturing their growth journey.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
