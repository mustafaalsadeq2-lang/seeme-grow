import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/auth_gate.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _iconAnimationController;
  late AnimationController _textAnimationController;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      icon: Icons.camera_alt_rounded,
      title: 'Capture Every Year',
      description: 'One photo per year, from birth to 18',
      gradient: const [Color(0xFF26A69A), Color(0xFF00897B)],
    ),
    OnboardingSlide(
      icon: Icons.auto_awesome_rounded,
      title: 'Watch Them Grow',
      description: 'Beautiful timeline of precious moments',
      gradient: const [Color(0xFF7E57C2), Color(0xFF5E35B1)],
    ),
    OnboardingSlide(
      icon: Icons.favorite_rounded,
      title: 'Cherish Forever',
      description: 'Safe, private, and always accessible',
      gradient: const [Color(0xFFEC407A), Color(0xFFD81B60)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconAnimationController.dispose();
    _textAnimationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });

    // Haptic feedback on page change
    HapticFeedback.lightImpact();

    // Restart animations for new page
    _iconAnimationController.reset();
    _textAnimationController.reset();
    _iconAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _textAnimationController.forward();
    });
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      // Navigate to AuthGate which will handle auth state and show appropriate screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AuthGate(),
        ),
      );
    }
  }

  void _skipOnboarding() {
    HapticFeedback.mediumImpact();
    _completeOnboarding();
  }

  void _nextPage() {
    HapticFeedback.mediumImpact();
    if (_currentPage < _slides.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_currentPage < _slides.length - 1)
                    AnimatedOpacity(
                      opacity: _currentPage < _slides.length - 1 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: TextButton(
                        onPressed: _skipOnboarding,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: _slides[_currentPage].gradient,
                          ).createShader(bounds),
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // PageView with slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _buildSlide(_slides[index], index);
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => _buildPageIndicator(index),
                ),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.9 + (value * 0.1),
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _slides[_currentPage].gradient,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _slides[_currentPage]
                                .gradient[0]
                                .withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _nextPage,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: Text(
                              _currentPage == _slides.length - 1
                                  ? 'Get Started'
                                  : 'Next',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(OnboardingSlide slide, int index) {
    final isCurrentPage = index == _currentPage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Icon with gradient background
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _iconAnimationController,
              curve: Curves.elasticOut,
            ),
            child: RotationTransition(
              turns: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _iconAnimationController,
                  curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                ),
              ),
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: slide.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: slide.gradient[0].withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: isCurrentPage ? 1.0 : 0.0),
                  duration: const Duration(milliseconds: 400),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.7 + (value * 0.3),
                      child: Icon(
                        slide.icon,
                        size: 80,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Animated Title
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _textAnimationController,
              curve: Curves.easeIn,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _textAnimationController,
                  curve: Curves.easeOut,
                ),
              ),
              child: Text(
                slide.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: 0.5,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Animated Description
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _textAnimationController,
              curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _textAnimationController,
                  curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                ),
              ),
              child: Text(
                slide.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final isActive = index == _currentPage;
    final gradient = _slides[index].gradient;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isActive ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            width: isActive ? 40 : 10,
            height: 10,
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      colors: gradient,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              color: !isActive
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)
                  : null,
              borderRadius: BorderRadius.circular(5),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: gradient[0].withValues(alpha: 0.4 * value),
                        blurRadius: 8 * value,
                        offset: Offset(0, 2 * value),
                      ),
                    ]
                  : null,
            ),
          ),
        );
      },
    );
  }
}

class OnboardingSlide {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;

  OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}
