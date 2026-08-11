import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "title": "Know Exactly Where You Stand",
      "description":
          "Most IT grads apply blindly\nand wonder why they get rejected. \n\nSkillProof shows you the gap in minutes.",
      "image": "assets/images/onboarding_1.svg",
    },
    {
      "title": "Your Personal Roadmap to Getting Hired",
      "description":
          "No more guessing. Just a clear,\n personalized plan built around your gaps",
      "image": "assets/images/onboarding_2.svg",
    },
    {
      "title": "SkillProof Shows You What to do Next",
      "description":
          "You're not behind.\n You just haven't had the right mirror yet.",
      "image": "assets/images/onboarding_3.svg",
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _onboardingData.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length + 1,
                itemBuilder: (context, index) {
                  if (index == _onboardingData.length) {
                    return _buildFinalScreen();
                  }
                  return _buildPage(
                    index: index,
                    title: _onboardingData[index]['title']!,
                    description: _onboardingData[index]['description']!,
                    imagePath: _onboardingData[index]['image']!,
                  );
                },
              ),
            ),
            if (_currentPage < _onboardingData.length) _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required int index,
    required String title,
    required String description,
    required String imagePath,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // SVG Illustration
          _wrapIllustration(
            context,
            Image.asset(
              imagePath.replaceAll('.svg', '.png'),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Icon(Icons.image_outlined, size: 80, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Dots Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _onboardingData.length,
              (dotIndex) => _buildDot(dotIndex),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: AppTextStyles.heading1.copyWith(
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  /// The onboarding illustrations are drawn for a light background, so on dark
  /// mode they float awkwardly. Sit them on a soft rounded light surface in
  /// dark mode so they read as intentional artwork; keep them transparent on
  /// light mode where the page background already matches.
  Widget _wrapIllustration(BuildContext context, Widget image) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final illustration = SizedBox(height: 280, child: image);
    if (!isDark) return illustration;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: SizedBox(height: 240, child: image),
    );
  }

  Widget _buildFinalScreen() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // Final Screen SVG
          _wrapIllustration(
            context,
            Image.asset(
              'assets/images/onboarding_4.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/Union.png', height: 80),
                  const SizedBox(height: 16),
                  Image.asset('assets/images/Type@40.png', height: 32),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "Start Your Journey Here",
            style: AppTextStyles.heading1.copyWith(
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Wirapath is where IT fresh graduates turn skill gaps into a validated proof.",
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(flex: 3),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/sign-in'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Sign In', style: AppTextStyles.buttonText),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go('/create-account'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Create Account',
                style: AppTextStyles.buttonText.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    if (_currentPage == 2) {
      // Screen 3: Full width Get Started button
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Get Started', style: AppTextStyles.buttonText),
          ),
        ),
      );
    }

    // Screen 1 & 2: Skip and Next
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {
              _pageController.animateToPage(
                _onboardingData.length,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            },
            child: Text(
              'Skip',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.white,
              elevation: 0,
              minimumSize: const Size(100, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32),
            ),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    bool isSelected = _currentPage == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFA600) : const Color(0xFFDFE2E6),
        shape: BoxShape.circle,
      ),
    );
  }
}
