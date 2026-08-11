import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/mock_db_service.dart';
import '../models/initial_test_model.dart';
import '../models/test_result_model.dart';
import '../models/career_simulation_model.dart';
import '../models/mini_project_model.dart';
import '../models/transcript_screening_model.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

class AuthNotifier extends Notifier<AsyncValue<UserModel?>> {
  @override
  AsyncValue<UserModel?> build() {
    Future.microtask(() => _init());
    return const AsyncValue.loading();
  }

  Future<void> _init() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final res = await apiService.getCurrentUser();
      final userData = res['result'];
      final user = UserModel.fromMap(
        Map<String, dynamic>.from(userData as Map),
        userData['id'].toString(),
      );
      state = AsyncValue.data(user);
    } catch (e) {
      // The auto-init that runs on app start may fail (no session yet) and
      // can race with a user set directly from a login/register response.
      // Only clear the state if no user has been set, so we never wipe out a
      // freshly logged-in profile.
      if (state.value == null) {
        state = const AsyncValue.data(null);
      }
    }
  }

  void setUser(UserModel user) {
    state = AsyncValue.data(user);
    _invalidateDashboard();
  }

  Future<void> refreshProfile() async {
    state = const AsyncValue.loading();
    await _init();
    _invalidateDashboard();
  }

  void logout() {
    state = const AsyncValue.data(null);
    _invalidateDashboard();
  }

  void _invalidateDashboard() {
    Future.microtask(() {
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(skillGapProvider);
      ref.invalidate(miniProjectsProvider);
      ref.invalidate(assessmentAnalyticsProvider);
      ref.invalidate(marketDemandProvider);
    });
  }
}

final userProfileProvider = NotifierProvider<AuthNotifier, AsyncValue<UserModel?>>(AuthNotifier.new);

// Since authStateProvider was used before, we map it to userProfileProvider for backward compatibility
final authStateProvider = Provider<AsyncValue<UserModel?>>((ref) {
  return ref.watch(userProfileProvider);
});

final dbServiceProvider = Provider<MockDbService>((ref) {
  return MockDbService(ref);
});

final initialTestsProvider = StreamProvider<List<InitialTestData>>((ref) {
  return ref.watch(dbServiceProvider).getInitialTests();
});

final userTestResultsProvider = StreamProvider<List<TestResultData>>((ref) {
  final userProfile = ref.watch(userProfileProvider).value;
  if (userProfile == null) return Stream.value([]);
  return ref.watch(dbServiceProvider).getTestResultsForUser(userProfile.uid);
});

final userSimulationSessionsProvider = StreamProvider<List<CareerSimulationSession>>((ref) async* {
  final userProfile = ref.watch(userProfileProvider).value;
  if (userProfile == null) {
    yield [];
    return;
  }
  
  final api = ref.read(apiServiceProvider);
  try {
    final rawData = await api.getSimulations();
    final sessions = rawData.map((e) => CareerSimulationSession.fromMap(e, '')).toList();
    
    // Cache to MockDbService so they exist locally as well
    final dbService = ref.read(dbServiceProvider);
    for (var session in sessions) {
      // Small hack: if we don't have it locally, this won't duplicate if we check, 
      // but MockDbService adds everything. Let's just yield the API data.
    }
    
    yield sessions;
  } catch (e) {
    // Fallback to local MockDbService if API fails or is unreachable
    yield* ref.watch(dbServiceProvider).getSimulationSessionsForUser(userProfile.uid);
  }
});

// Dynamic dashboard summary from API
final dashboardSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = ref.watch(userProfileProvider).value;
  if (user == null) return {};
  final api = ref.read(apiServiceProvider);
  return api.getDashboardSummary();
});

// Dynamic skill gap analysis from API
final skillGapProvider = FutureProvider<List<dynamic>>((ref) async {
  final user = ref.watch(userProfileProvider).value;
  if (user == null) return [];
  final api = ref.read(apiServiceProvider);
  return api.getSkillGap();
});

// Assessment analytics — single source of truth shared with the website
// (overall readiness, skills mapped, critical gaps, strengths, per-category map).
final assessmentAnalyticsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final user = ref.watch(userProfileProvider).value;
  if (user == null) return {'has_assessment': false};
  final api = ref.read(apiServiceProvider);
  return api.getAssessmentAnalytics();
});

// Initial-test questions — the same role-mapped problem set the website serves.
final assessmentQuestionsProvider =
    FutureProvider<List<dynamic>>((ref) async {
  final user = ref.watch(userProfileProvider).value;
  if (user == null) return [];
  final api = ref.read(apiServiceProvider);
  return api.getAssessmentQuestions();
});

// Market demand — top-10 in-demand skills for the user's chosen role.
final marketDemandProvider = FutureProvider<List<dynamic>>((ref) async {
  final user = ref.watch(userProfileProvider).value;
  if (user == null) return [];
  final api = ref.read(apiServiceProvider);
  return api.getMarketDemand();
});

// Dynamic mini projects matched to target role from API
final miniProjectsProvider = FutureProvider<List<MiniProject>>((ref) async {
  final user = ref.watch(userProfileProvider).value;
  if (user == null) return [];
  final api = ref.read(apiServiceProvider);
  final list = await api.fetchMiniProjects();
  return list.map((x) => MiniProject.fromMap(Map<String, dynamic>.from(x), x['id'].toString())).toList();
});

// Full user profile from backend (includes github_username + linked providers).
// Used by the Integrations page to show real GitHub connection status.
final githubProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = ref.watch(userProfileProvider).value;
  if (user == null) return {};
  final api = ref.read(apiServiceProvider);
  return api.getUserProfile(user.uid);
});


