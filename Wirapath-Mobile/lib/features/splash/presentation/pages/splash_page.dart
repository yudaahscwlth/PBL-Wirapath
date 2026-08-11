import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _dissolveController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _logoDissolveAnimation;
  late Animation<double> _screenFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Phase 1: Fade in the centered logo
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Phase 2: Dissolve logo and fade screen
    _dissolveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _logoDissolveAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _dissolveController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
    ));

    _screenFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _dissolveController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    _startAnimation();
  }

  void _startAnimation() async {
    // Phase 1: Fade in
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();

    // Hold for a moment
    await Future.delayed(const Duration(milliseconds: 2500));

    // Phase 2: Dissolve & navigate
    _dissolveController.forward();
    await Future.delayed(const Duration(milliseconds: 1100));

    if (mounted) {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _dissolveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AnimatedBuilder(
        animation: Listenable.merge([_fadeController, _dissolveController]),
        builder: (context, child) {
          return Opacity(
            opacity: _screenFadeAnimation.value,
            child: Center(
              child: FadeTransition(
                opacity: _logoDissolveAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/Union.png',
                        width: 80,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      Image.asset(
                        'assets/images/Type@40.png',
                        width: 120,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
