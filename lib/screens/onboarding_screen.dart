import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_tokens.dart';
import 'auth/sign_in_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _controller = PageController();
  int _page = 0;

  static const _totalPages = 3;

  late final AnimationController _heroController;
  late final Animation<double> _heroFade;
  late final Animation<double> _heroSlide;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _heroFade = CurvedAnimation(
      parent: _heroController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _heroSlide = CurvedAnimation(
      parent: _heroController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _heroController.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }

  void _next() {
    if (_page < _totalPages - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _totalPages - 1;

    return Scaffold(
      backgroundColor: T.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip ─────────────────────────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
                child: AnimatedOpacity(
                  opacity: isLast ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap: _complete,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 14,
                        color: T.ink3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Pages ─────────────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _Page1(fadeAnim: _heroFade, slideAnim: _heroSlide),
                  const _Page2(),
                  const _Page3(),
                ],
              ),
            ),

            // ── Pager dots ───────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalPages, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? T.forest : T.ink4,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),

            // ── Continue button ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: T.ink,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isLast ? 'Get Started' : 'Continue',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page 1 — fanned polaroids + headline ──────────────────────────────────

class _Page1 extends StatelessWidget {
  final Animation<double> fadeAnim;
  final Animation<double> slideAnim;

  const _Page1({required this.fadeAnim, required this.slideAnim});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // ── Fanned polaroid frames ────────────────────────────────────────
          Expanded(
            flex: 5,
            child: FadeTransition(
              opacity: fadeAnim,
              child: AnimatedBuilder(
                animation: slideAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, 30 * (1 - slideAnim.value)),
                  child: child,
                ),
                child: _FannedPolaroids(),
              ),
            ),
          ),

          // ── Headline ──────────────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: FadeTransition(
              opacity: fadeAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'A childhood,',
                    style: serif(
                      fontSize: 34,
                      fontWeight: FontWeight.w400,
                      height: 1.15,
                      color: T.ink,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'in nineteen frames.',
                          style: serif(
                            fontSize: 34,
                            fontWeight: FontWeight.w600,
                            italic: true,
                            color: T.forest,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'One photo per year,\nfrom birth to eighteen.',
                    style: TextStyle(
                      fontSize: 15,
                      color: T.ink3,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fanned polaroids widget ────────────────────────────────────────────────

class _FannedPolaroids extends StatelessWidget {
  static const _frames = [
    _PolaroidData(color: Color(0xFFD4E8D4), rotation: -9.0, dx: -28.0, dy: 18.0, label: 'Year One'),
    _PolaroidData(color: Color(0xFFE8D4C4), rotation: 5.0,  dx: 20.0,  dy: 8.0,  label: 'Year Nine'),
    _PolaroidData(color: Color(0xFFC4D4E8), rotation: -2.0, dx: 0.0,   dy: 0.0,  label: 'Birth'),
  ];

  const _FannedPolaroids();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 240,
        height: 300,
        child: Stack(
          alignment: Alignment.center,
          children: _frames.map((f) => _Polaroid(data: f)).toList(),
        ),
      ),
    );
  }
}

class _PolaroidData {
  final Color color;
  final double rotation;
  final double dx;
  final double dy;
  final String label;

  const _PolaroidData({
    required this.color,
    required this.rotation,
    required this.dx,
    required this.dy,
    required this.label,
  });
}

class _Polaroid extends StatelessWidget {
  final _PolaroidData data;

  const _Polaroid({required this.data});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(data.dx, data.dy),
      child: Transform.rotate(
        angle: data.rotation * math.pi / 180,
        child: Container(
          width: 170,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Photo area
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: data.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),
              // Label
              Text(
                data.label,
                style: serif(
                  fontSize: 11,
                  color: T.ink3,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Page 2 — feature highlight ────────────────────────────────────────────

class _Page2 extends StatelessWidget {
  const _Page2();

  static const _features = [
    (Icons.photo_camera_outlined, 'One photo per year', 'Capture a single moment — no clutter, just growth.'),
    (Icons.timeline_outlined, '19 year journey', 'From birth to eighteen, all in one place.'),
    (Icons.compare_arrows_outlined, 'See them grow', 'Compare any two years side by side.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Text(
            'Everything they need.',
            style: serif(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              italic: true,
              color: T.forest,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            "Nothing they don't.",
            style: serif(
              fontSize: 32,
              fontWeight: FontWeight.w400,
              color: T.ink,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ..._features.map((f) => _FeatureRow(
            icon: f.$1,
            title: f.$2,
            body: f.$3,
          )),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: T.forestSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: T.forest, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: T.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    color: T.ink3,
                    height: 1.5,
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

// ── Page 3 — sign in CTA ──────────────────────────────────────────────────

class _Page3 extends StatelessWidget {
  const _Page3();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppMark(size: 64),
          const SizedBox(height: 32),
          Text(
            'Their story,',
            style: serif(
              fontSize: 36,
              fontWeight: FontWeight.w400,
              color: T.ink,
              height: 1.15,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            'forever.',
            style: serif(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              italic: true,
              color: T.forest,
              height: 1.15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'Sign in to keep their memories\nsafe across all your devices.',
            style: TextStyle(
              fontSize: 15,
              color: T.ink3,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
