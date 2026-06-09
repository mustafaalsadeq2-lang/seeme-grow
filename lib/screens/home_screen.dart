import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/child.dart';
import '../services/notification_service.dart';
import '../storage/local_storage_service.dart';
import '../utils/age_calculator.dart';
import '../utils/app_tokens.dart';
import 'add_child_screen.dart';
import 'auth/sign_in_screen.dart';
import 'edit_child_screen.dart';
import 'settings_screen.dart';
import 'timeline_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  List<Child> _children = [];
  bool _syncing = false;
  late final AnimationController _entryController;

  // ── Auth state ───────────────────────────────────────────────────────────
  bool _guestModeEnabled    = false;
  bool _isReviewerSignedIn  = false;
  String? _reviewerEmail;
  StreamSubscription<AuthState>? _authSub;

  SupabaseClient get _supabase => Supabase.instance.client;

  bool get _isEffectivelySignedIn =>
      _supabase.auth.currentSession != null || _isReviewerSignedIn;

  String? get _effectiveEmail =>
      _supabase.auth.currentUser?.email ?? _reviewerEmail;

  bool get _isGuest => !_isEffectivelySignedIn && _guestModeEnabled;

  // ── Init / dispose ────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadAuthFlags();
    _loadChildren();
    _syncFromCloud();
    _initNotifications();
    _setupAuthStream();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _entryController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAuthFlags();
      _loadChildren();
      _syncFromCloud();
    }
  }

  // ── Auth flags ────────────────────────────────────────────────────────────

  Future<void> _loadAuthFlags() async {
    final prefs        = await SharedPreferences.getInstance();
    final isReviewer   = prefs.getBool('is_reviewer_signed_in') ?? false;
    final reviewerEmail= prefs.getString('reviewer_email');
    final guestMode    = prefs.getBool('is_guest_mode') ?? false;
    final hasSession   = _supabase.auth.currentSession != null;

    if (!mounted) return;
    setState(() {
      _isReviewerSignedIn = isReviewer;
      _reviewerEmail      = reviewerEmail;
      _guestModeEnabled   = guestMode && !hasSession && !isReviewer;
    });
  }

  void _setupAuthStream() {
    _authSub = _supabase.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        // Do NOT call _syncFromCloud() here — race condition with
        // verify_code_screen's Keep & Sync / Start Fresh dialog.
        _loadAuthFlags();
        _loadChildren();
      } else if (event == AuthChangeEvent.signedOut) {
        _loadAuthFlags();
        setState(() => _children = []);
      } else {
        _loadAuthFlags();
      }
    });
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  Future<void> _initNotifications() async {
    await NotificationService.init();
    await NotificationService.testNotification();
  }

  // ── Local data ────────────────────────────────────────────────────────────

  Future<void> _loadChildren() async {
    final children = await LocalStorageService.loadChildren();

    children.sort((a, b) => b.birthDate.compareTo(a.birthDate));

    if (!mounted) return;
    setState(() => _children = children);
    if (!_entryController.isCompleted) {
      _entryController.forward();
    }
    NotificationService.scheduleAll();
  }

  // ── Cloud sync ────────────────────────────────────────────────────────────

  Future<void> _syncFromCloud() async {
    final user = _supabase.auth.currentUser;
    if (user == null || _syncing) return;

    setState(() => _syncing = true);

    try {
      final response = await _supabase
          .from('children')
          .select()
          .eq('user_id', user.id);

      final local    = await LocalStorageService.loadChildren();
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

  // ── Auth actions ──────────────────────────────────────────────────────────

  Future<void> _logout() async {
    // Do not clear local data on logout. Current production behavior keeps
    // local children/photos because cloud sync is not yet a full upload path.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest_mode', true);
    await prefs.setBool('is_reviewer_signed_in', false);
    await prefs.remove('reviewer_email');
    await prefs.remove('last_user_id');
    await prefs.remove('_lastAuthUserId');

    if (_isReviewerSignedIn) {
      // Reviewer path — no real Supabase session to sign out from.
      if (mounted) {
        setState(() {
          _isReviewerSignedIn = false;
          _reviewerEmail      = null;
          _guestModeEnabled   = true;
        });
      }
    } else {
      await _supabase.auth.signOut();
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

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
        builder: (_) => AddChildScreen(existingNames: existingNames),
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
      MaterialPageRoute(builder: (_) => EditChildScreen(child: child)),
    );
    if (changed == true) _loadChildren();
  }

  Future<void> _deleteChild(Child child) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove child'),
        content: Text(
          'This will permanently delete all memories for ${child.name}.\n'
          'This action cannot be undone.',
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

  // ── UI helpers ────────────────────────────────────────────────────────────

  static const _quotes = [
    'Every moment with your child is a memory worth keeping.',
    'Children grow so fast — capture every smile.',
    'The littlest feet make the biggest footprints in our hearts.',
    'A child’s laughter is the best sound in the world.',
    'Today’s little moments become tomorrow’s precious memories.',
    'Watching you grow is the greatest adventure.',
    'Every day is a new chapter in your child’s story.',
    'The best thing to spend on your child is time.',
    'In the eyes of a child, you will see the world as it should be.',
    'Childhood is a short season — make it sweet.',
    'One day you’ll look back and realize these were the big moments.',
    'Growth is a journey best measured in love.',
    'Small hands, big dreams — capture them all.',
    'The days are long but the years are short.',
    'Every photo tells a story of how much they’ve grown.',
  ];

  Color _avatarColor(String localId) {
    final colors = [
      Colors.purple, Colors.blue, Colors.teal,
      Colors.indigo, Colors.orange, Colors.pink, Colors.green,
    ];
    return colors[localId.hashCode.abs() % colors.length];
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning!';
    if (hour < 17) return 'Good Afternoon!';
    return 'Good Evening!';
  }

  int _totalMemories() {
    int count = 0;
    for (final c in _children) {
      count += c.yearPhotos.values.where((p) => p.trim().isNotEmpty).length;
    }
    return count;
  }

  int? _daysToNextBirthday() {
    if (_children.isEmpty) return null;
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int? minDays;
    for (final c in _children) {
      var next = DateTime(now.year, c.birthDate.month, c.birthDate.day);
      if (next.isBefore(today) || next.isAtSameMomentAs(today)) {
        next = DateTime(now.year + 1, c.birthDate.month, c.birthDate.day);
      }
      final diff = next.difference(today).inDays;
      if (minDays == null || diff < minDays) minDays = diff;
    }
    return minDays;
  }

  String? _latestPhoto(Child child) {
    final entries = child.yearPhotos.entries
        .where((e) => e.value.trim().isNotEmpty)
        .toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    for (final e in entries) {
      if (File(e.value).existsSync()) return e.value;
    }
    return null;
  }

  int _memoryCount(Child child) =>
      child.yearPhotos.values.where((p) => p.trim().isNotEmpty).length;

  String _dailyQuote() {
    final now       = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return _quotes[dayOfYear % _quotes.length];
  }

  // ── Animations ────────────────────────────────────────────────────────────

  Animation<double> _stagger(double begin, double end) {
    return CurvedAnimation(
      parent: _entryController,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  Widget _animatedSlide(Animation<double> animation, Widget child) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, ch) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, 30 * (1 - animation.value)),
          child: ch,
        ),
      ),
      child: child,
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    final email   = _effectiveEmail;
    final initial = (email != null && email.isNotEmpty)
        ? email[0].toUpperCase()
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
      child: Row(
        children: [
          Text(
            'SeeMe',
            style: serif(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: T.ink,
            ),
          ),
          Text(
            ' Grow',
            style: serif(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              italic: true,
              color: T.forest,
            ),
          ),
          const Spacer(),
          if (_syncing)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'settings') {
                _openSettings();
              } else if (value == 'logout') {
                _logout();
              } else if (value == 'signin') {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                  (route) => false,
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'settings',
                child: Text('Settings'),
              ),
              if (_isEffectivelySignedIn)
                const PopupMenuItem(
                  value: 'logout',
                  child: Text('Logout', style: TextStyle(color: Colors.red)),
                )
              else
                const PopupMenuItem(
                  value: 'signin',
                  child: Text('Sign In'),
                ),
            ],
            child: CircleAvatar(
              radius: 18,
              backgroundColor: _isEffectivelySignedIn
                  ? T.forest
                  : Colors.grey.shade200,
              child: initial != null
                  ? Text(
                      initial,
                      style: TextStyle(
                        color: _isEffectivelySignedIn
                            ? Colors.white
                            : T.ink3,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 18,
                      color: _isEffectivelySignedIn ? Colors.white : T.ink3,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Camera pill (add button) ───────────────────────────────────────────────

  Widget _buildCameraPill() {
    return GestureDetector(
      onTap: _addChild,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
        decoration: BoxDecoration(
          color: T.ink,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Add Child',
              style: serif(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar is ALWAYS rendered, regardless of children count.
            _buildTopBar(),
            const SizedBox(height: 8),

            // Content area
            Expanded(
              child: _children.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                      children: [
                        _buildGreeting(),
                        const SizedBox(height: 16),
                        _buildStatsCard(),
                        const SizedBox(height: 24),
                        ..._children.asMap().entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildChildCard(e.value, e.key),
                              ),
                            ),
                        _buildQuote(),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildCameraPill(),
    );
  }

  // ── Greeting ──────────────────────────────────────────────────────────────

  Widget _buildGreeting() {
    final theme = Theme.of(context);
    return _animatedSlide(
      _stagger(0.0, 0.4),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Here's your family overview",
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats card ────────────────────────────────────────────────────────────

  Widget _buildStatsCard() {
    final theme    = Theme.of(context);
    final memories = _totalMemories();
    final nextBday = _daysToNextBirthday();

    return _animatedSlide(
      _stagger(0.15, 0.55),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statColumn(Icons.child_care, '${_children.length}', 'Children', theme),
            _statColumn(Icons.photo_library_outlined, '$memories', 'Memories', theme),
            _statColumn(
              Icons.cake_outlined,
              nextBday != null ? '$nextBday' : '-',
              nextBday != null ? 'Days to B-day' : 'No birthday',
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(IconData icon, String value, String label, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  // ── Child card ────────────────────────────────────────────────────────────

  Widget _buildChildCard(Child child, int index) {
    final theme    = Theme.of(context);
    final age      = AgeCalculator.currentAge(child.birthDate);
    final photo    = _latestPhoto(child);
    final memories = _memoryCount(child);
    final color    = _avatarColor(child.localId);

    final begin = (0.25 + index * 0.08).clamp(0.0, 0.85);
    final end   = (begin + 0.4).clamp(0.0, 1.0);

    return _animatedSlide(
      _stagger(begin, end),
      Card(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TimelineScreen(childId: child.localId),
              ),
            );
            _loadChildren();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: color,
                  backgroundImage:
                      photo != null ? FileImage(File(photo)) : null,
                  child: photo == null
                      ? Text(
                          child.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        age.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$memories ${memories == 1 ? 'memory' : 'memories'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') { _editChild(child); }
                    else if (value == 'delete') { _deleteChild(child); }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Quote ─────────────────────────────────────────────────────────────────

  Widget _buildQuote() {
    final theme = Theme.of(context);
    return _animatedSlide(
      _stagger(0.5, 1.0),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        child: Text(
          '"${_dailyQuote()}"',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            height: 1.5,
          ),
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _greeting(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 32),
            Icon(
              Icons.child_care,
              size: 88,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'No children added yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start by adding your child to begin\ncapturing their growth journey.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '"${_dailyQuote()}"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                height: 1.5,
              ),
            ),
            if (_isGuest) ...[
              const SizedBox(height: 24),
              Text(
                'Sign in to sync across devices.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: T.forest,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

