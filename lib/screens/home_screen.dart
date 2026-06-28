import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:seeme_grow_clean/l10n/app_localizations.dart';
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
        _loadAuthFlags();
        _loadChildren();   // show any existing local data immediately
        _syncFromCloud();  // then merge cloud data in background
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
    final all = await LocalStorageService.loadChildren();

    // Hide children that belong to a signed-in account once that account
    // is logged out. Local data is preserved on disk — it simply isn't
    // shown until the same account signs back in. Guest-added children
    // (userId == null) are never hidden, keeping guest mode intact.
    final currentUserId = _supabase.auth.currentUser?.id;
    final children = all
        .where((c) => c.userId == null || c.userId == currentUserId)
        .toList();

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
    debugPrint('🔄 _syncFromCloud: user=${user.id}');

    try {
      // ── Phase 1: Restore children ──────────────────────────────────────
      final response = await _supabase
          .from('children')
          .select()
          .eq('user_id', user.id);

      debugPrint('🔄 _syncFromCloud: ${response.length} child rows returned');

      final local    = await LocalStorageService.loadChildren();
      final localIds = local.map((c) => c.localId).toSet();

      for (final row in response) {
        final cloudChild = Child.fromJson(row);
        debugPrint('  → ${cloudChild.name} (local_id=${cloudChild.localId})');
        if (!localIds.contains(cloudChild.localId)) {
          local.add(cloudChild);
        }
      }

      await LocalStorageService.saveChildren(local);

      // ── Phase 2: Restore photos ────────────────────────────────────────
      // Map cloud child id → index in local list.
      final cloudIdToIdx = <String, int>{};
      for (final row in response) {
        final cloudId = row['id'] as String?;
        final localId = (row['local_id'] ?? row['localId']) as String?;
        if (cloudId == null || localId == null) continue;
        final idx = local.indexWhere((c) => c.localId == localId);
        if (idx != -1) cloudIdToIdx[cloudId] = idx;
      }

      if (cloudIdToIdx.isNotEmpty) {
        final inClause = '(${cloudIdToIdx.keys.join(',')})';
        final photoRows = await _supabase
            .from('year_photos')
            .select()
            .filter('child_id', 'in', inClause);

        debugPrint('🔄 _syncFromCloud: ${photoRows.length} photo rows returned');

        final appDir = await getApplicationDocumentsDirectory();
        bool photosChanged = false;

        for (final photoRow in photoRows) {
          final childId = photoRow['child_id'] as String?;
          final year    = photoRow['year'];
          final imgPath = photoRow['image_path'] as String?;

          debugPrint('  📸 child_id=$childId year=$year path=$imgPath');

          if (childId == null || year == null || imgPath == null) continue;

          final idx = cloudIdToIdx[childId];
          if (idx == null) continue;

          if (year is! int) continue;
          final yearInt = year;

          // Skip if a valid local file already exists for this year.
          final existing = local[idx].yearPhotos[yearInt];
          if (existing != null &&
              existing.isNotEmpty &&
              File(existing).existsSync()) {
            debugPrint('  ⏭️ year $yearInt already local — skipping');
            continue;
          }

          try {
            final bytes = await _supabase.storage
                .from('SeeMeGrow')
                .download(imgPath);

            final childDir =
                Directory('${appDir.path}/${local[idx].localId}');
            if (!await childDir.exists()) {
              await childDir.create(recursive: true);
            }

            final ts = DateTime.now().millisecondsSinceEpoch;
            final localFilePath =
                '${childDir.path}/year_${yearInt}_$ts.jpg';
            await File(localFilePath).writeAsBytes(bytes);

            local[idx].yearPhotos[yearInt] = localFilePath;
            photosChanged = true;

            debugPrint('  ✅ Saved: year=$yearInt → $localFilePath');
          } catch (e) {
            debugPrint('  ⚠️ Failed year=$yearInt path=$imgPath: $e');
          }
        }

        if (photosChanged) {
          await LocalStorageService.saveChildren(local);
        }
      }

      await _loadChildren();
    } catch (e) {
      debugPrint('⚠️ _syncFromCloud failed: $e');
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
          _children           = [];
        });
      }
    } else {
      await _supabase.auth.signOut();
      // Clear the visible list immediately — don't wait on the auth
      // stream event, which can race with a pending _syncFromCloud().
      if (mounted) {
        setState(() {
          _guestModeEnabled = true;
          _children         = [];
        });
      }
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (!mounted) return;
    // Reload auth flags after returning from settings so that a reviewer logout
    // (which has no Supabase signedOut event) is reflected in this screen.
    await _loadAuthFlags();
    if (!_isEffectivelySignedIn) setState(() => _children = []);
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

    if (result == null) return;

    // 1. Save locally first — always succeeds regardless of connectivity.
    await LocalStorageService.addChild(result);

    // 2. Attempt cloud upsert if signed in.
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final response = await _supabase
            .from('children')
            .upsert(
              {
                'user_id'   : user.id,
                'local_id'  : result.localId,
                'name'      : result.name,
                'birth_date': result.birthDate.toIso8601String(),
              },
              onConflict: 'local_id,user_id',
            )
            .select('id')
            .single();

        final cloudId = response['id'] as String;
        await LocalStorageService.updateChild(
          result.copyWith(
            userId    : user.id,
            cloudId   : cloudId,
            syncState : SyncState.synced,
          ),
        );
        debugPrint('✅ Child synced to cloud: ${result.name} → $cloudId');
      } catch (e) {
        // Non-fatal: child is already saved locally above.
        debugPrint('⚠️ Child cloud sync failed: $e');
        await LocalStorageService.updateChild(
          result.copyWith(
            userId   : user.id,
            syncState: SyncState.failed,
          ),
        );
      }
    }

    await NotificationService.scheduleAll();
    _loadChildren();
  }

  Future<void> _editChild(Child child) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditChildScreen(child: child)),
    );
    if (changed == true) _loadChildren();
  }

  Future<void> _deleteChild(Child child) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.removeChildTitle),
        content: Text(l10n.removeChildConfirm(child.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await NotificationService.cancelForChild(child.localId);
      await LocalStorageService.deleteChild(child.localId);

      // Best-effort cloud delete — local delete already committed above.
      final user = _supabase.auth.currentUser;
      if (user != null) {
        try {
          await _supabase
              .from('children')
              .delete()
              .eq('user_id', user.id)
              .eq('local_id', child.localId);
          debugPrint('✅ Child deleted from cloud: ${child.name}');
        } catch (e) {
          debugPrint('⚠️ Child cloud delete failed: $e');
        }
      }

      _loadChildren();
    }
  }

  // ── UI helpers ────────────────────────────────────────────────────────────

  List<String> _quotes(AppLocalizations l10n) => [
    l10n.quote01, l10n.quote02, l10n.quote03, l10n.quote04, l10n.quote05,
    l10n.quote06, l10n.quote07, l10n.quote08, l10n.quote09, l10n.quote10,
    l10n.quote11, l10n.quote12, l10n.quote13, l10n.quote14, l10n.quote15,
  ];

  Color _avatarColor(String localId) {
    final colors = [
      Colors.purple, Colors.blue, Colors.teal,
      Colors.indigo, Colors.orange, Colors.pink, Colors.green,
    ];
    return colors[localId.hashCode.abs() % colors.length];
  }

  String _greeting() {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.goodMorning;
    if (hour < 17) return l10n.goodAfternoon;
    return l10n.goodEvening;
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

  int _memoryCount(Child child) => child.yearPhotos.values
      .where((p) => p.trim().isNotEmpty && File(p).existsSync())
      .length;

  String _dailyQuote() {
    final l10n      = AppLocalizations.of(context)!;
    final quotes    = _quotes(l10n);
    final now       = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return quotes[dayOfYear % quotes.length];
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
            itemBuilder: (_) {
              final l10n = AppLocalizations.of(context)!;
              return [
                PopupMenuItem(
                  value: 'settings',
                  child: Text(l10n.settingsAction),
                ),
                if (_isEffectivelySignedIn)
                  PopupMenuItem(
                    value: 'logout',
                    child: Text(l10n.logoutAction, style: const TextStyle(color: Colors.red)),
                  )
                else
                  PopupMenuItem(
                    value: 'signin',
                    child: Text(l10n.signInAction),
                  ),
              ];
            },
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
              AppLocalizations.of(context)!.addChild,
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
    final l10n = AppLocalizations.of(context)!;
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
            l10n.familyOverview,
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
            _statColumn(Icons.child_care, '${_children.length}', AppLocalizations.of(context)!.childrenLabel, theme),
            _statColumn(Icons.photo_library_outlined, '$memories', AppLocalizations.of(context)!.memoriesLabel, theme),
            _statColumn(
              Icons.cake_outlined,
              nextBday != null ? '$nextBday' : '-',
              nextBday != null ? AppLocalizations.of(context)!.daysToBirthday : AppLocalizations.of(context)!.noBirthday,
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
    final l10n     = AppLocalizations.of(context)!;
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
                        age.format(l10n),
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        () {
                          final l10n = AppLocalizations.of(context)!;
                          return '$memories ${memories == 1 ? l10n.memorySingular : l10n.memoriesPlural}';
                        }(),
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
                  itemBuilder: (_) {
                    final l10n = AppLocalizations.of(context)!;
                    return [
                      PopupMenuItem(value: 'edit', child: Text(l10n.editAction)),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.deleteAction, style: const TextStyle(color: Colors.red)),
                      ),
                    ];
                  },
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
    final l10n = AppLocalizations.of(context)!;
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
              l10n.noChildrenYet,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.startByAdding,
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
                l10n.signInToKeep,
                textAlign: TextAlign.center,
                style: const TextStyle(
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

