import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/create_account_page.dart';
import '../../features/auth/presentation/pages/oauth_callback_page.dart';
import '../../features/auth/presentation/pages/terms_conditions_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/assessment/presentation/pages/assessment_page.dart';
import '../../features/assessment/presentation/pages/connect_github_page.dart';
import '../../features/readiness/presentation/pages/cv_screening_page.dart';
import '../../features/readiness/presentation/pages/initial_test_page.dart';
import '../../features/readiness/presentation/pages/data_analysis_test_page.dart';
import '../../features/readiness/presentation/pages/data_analysis_review_page.dart';
import '../../features/readiness/presentation/pages/ux_design_test_page.dart';
import '../../features/readiness/presentation/pages/ux_design_review_page.dart';
import '../../features/readiness/presentation/pages/testing_test_page.dart';
import '../../features/readiness/presentation/pages/testing_review_page.dart';
import '../../features/readiness/presentation/pages/review_test_page.dart';
import '../../features/readiness/presentation/pages/cv_screening_result_page.dart';

import '../../features/devhub/presentation/pages/project_detail_page.dart';
import '../../features/devhub/presentation/pages/project_workspace_page.dart';
import '../../features/main/main_shell.dart';
import '../../features/profile/presentation/pages/personal_information_page.dart';
import '../../features/profile/presentation/pages/password_security_page.dart';
import '../../features/profile/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/language_appearance_page.dart';
import '../../features/profile/presentation/pages/integrations_page.dart';
import '../../features/profile/presentation/pages/help_support_page.dart';
import '../../features/simulation/presentation/pages/jobdesk_analyzer_page.dart';
import '../../core/models/mini_project_model.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      if (state.uri.scheme == 'wirapath') {
        final host = state.uri.host;
        final path = state.uri.path;
        String normalizedPath = '/$host$path';
        if (normalizedPath.endsWith('/') && normalizedPath.length > 1) {
          normalizedPath = normalizedPath.substring(0, normalizedPath.length - 1);
        }
        final newUri = Uri(path: normalizedPath, queryParameters: state.uri.queryParameters);
        return newUri.toString();
      }
      return null;
    },
    routes: [
      // --- Splash, Onboarding & Auth ---
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: '/create-account',
        builder: (context, state) => const CreateAccountPage(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsConditionsPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/oauth-callback',
        builder: (context, state) {
          final accessToken = state.uri.queryParameters['access_token'];
          final refreshToken = state.uri.queryParameters['refresh_token'];
          return OAuthCallbackPage(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );
        },
      ),
      GoRoute(
        path: '/assessment',
        builder: (context, state) => const AssessmentPage(),
      ),
      GoRoute(
        path: '/connect-github',
        builder: (context, state) => const ConnectGithubPage(),
      ),

      // --- Main Tabs ---
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainShell(currentIndex: 0),
      ),
      GoRoute(
        path: '/simulation',
        builder: (context, state) => const MainShell(currentIndex: 3),
      ),
      GoRoute(
        path: '/jobdesk-analyzer',
        builder: (context, state) => const JobdeskAnalyzerPage(),
      ),
      GoRoute(
        path: '/readiness-center',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          // Tab can come from navigation extra or a ?tab= query param (deep link).
          final tabParam = int.tryParse(state.uri.queryParameters['tab'] ?? '');
          final initialTabIndex = extra?['initialTabIndex'] as int? ?? tabParam ?? 0;
          return MainShell(
            currentIndex: 1,
            initialReadinessTabIndex: initialTabIndex,
          );
        },
      ),

      GoRoute(
        path: '/readiness-center/initial-test',
        builder: (context, state) => const MainShell(
          currentIndex: 1,
          child: InitialTestPage(),
        ),
      ),
      GoRoute(
        path: '/readiness-center/review-test',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MainShell(
            currentIndex: 1,
            child: ReviewTestPage(extraResult: extra),
          );
        },
      ),
      GoRoute(
        path: '/readiness-center/data-analysis-test',
        builder: (context, state) => const MainShell(
          currentIndex: 1,
          child: DataAnalysisTestPage(),
        ),
      ),
      GoRoute(
        path: '/readiness-center/data-analysis-review',
        builder: (context, state) => const MainShell(
          currentIndex: 1,
          child: DataAnalysisReviewPage(),
        ),
      ),
      GoRoute(
        path: '/readiness-center/ux-design-test',
        builder: (context, state) => const MainShell(
          currentIndex: 1,
          child: UXDesignTestPage(),
        ),
      ),
      GoRoute(
        path: '/readiness-center/ux-design-review',
        builder: (context, state) => const MainShell(
          currentIndex: 1,
          child: UXDesignReviewPage(),
        ),
      ),
      GoRoute(
        path: '/readiness-center/testing-test',
        builder: (context, state) => const MainShell(
          currentIndex: 1,
          child: TestingTestPage(),
        ),
      ),
      GoRoute(
        path: '/readiness-center/testing-review',
        builder: (context, state) => const MainShell(
          currentIndex: 1,
          child: TestingReviewPage(),
        ),
      ),
      GoRoute(
        path: '/cv-screening',
        builder: (context, state) => const MainShell(
          currentIndex: 1,
          child: CvScreeningPage(),
        ),
      ),
      GoRoute(
        path: '/cv-screening-result',
        builder: (context, state) => MainShell(
          currentIndex: 1,
          child: CvScreeningResultPage(
            result: state.extra is Map<String, dynamic>
                ? state.extra as Map<String, dynamic>
                : null,
          ),
        ),
      ),

      // --- DevHub ---
      GoRoute(
        path: '/devhub',
        builder: (context, state) => const MainShell(currentIndex: 2),
      ),

      // Dynamic project detail (universal for all projects)
      GoRoute(
        path: '/devhub/project/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as MiniProject?;
          return ProjectDetailPage(
            projectId: id,
            projectFromExtra: extra,
          );
        },
      ),

      // Dynamic project workspace/submit (universal)
      GoRoute(
        path: '/devhub/project/:id/workspace',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as MiniProject?;
          return ProjectWorkspacePage(
            projectId: id,
            projectFromExtra: extra,
          );
        },
      ),

      // --- Profile ---
      GoRoute(
        path: '/profile',
        builder: (context, state) => const MainShell(currentIndex: 4),
      ),
      GoRoute(
        path: '/personal-information',
        builder: (context, state) => const PersonalInformationPage(),
      ),
      GoRoute(
        path: '/password-security',
        builder: (context, state) => const PasswordSecurityPage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/language-appearance',
        builder: (context, state) => const LanguageAppearancePage(),
      ),
      GoRoute(
        path: '/integrations',
        builder: (context, state) => const IntegrationsPage(),
      ),
      GoRoute(
        path: '/help-support',
        builder: (context, state) => const HelpSupportPage(),
      ),
    ],
  );
}
