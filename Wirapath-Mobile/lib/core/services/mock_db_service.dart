import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/initial_test_model.dart';
import '../models/test_result_model.dart';
import '../models/career_simulation_model.dart';
import '../models/mini_project_model.dart';
import '../models/chat_message_model.dart';
import '../providers/user_provider.dart';
import '../../features/initial_test/domain/entities/initial_test_data.dart' show InitialTestDataConv;
import '../../features/initial_test/domain/entities/mock_initial_tests.dart' as mock_tests;

import 'api_service.dart';

class MockDbService {
  final Ref ref;

  MockDbService(this.ref);

  // In-memory databases
  static final List<TestResultData> _testResults = [];
  static final List<CareerSimulationSession> _sessions = [];
  static final Map<String, List<ChatMessage>> _sessionMessages = {};

  // Broadcasters for reactive streams
  static final StreamController<List<TestResultData>> _testResultsController = 
      StreamController<List<TestResultData>>.broadcast();
  static final StreamController<List<CareerSimulationSession>> _sessionsController =
      StreamController<List<CareerSimulationSession>>.broadcast();
  static final Map<String, StreamController<List<ChatMessage>>> _chatControllers = {};

  Stream<List<InitialTestData>> getInitialTests() {
    return Stream.value([
      mock_tests.programmingTestData.toCore().copyWith(id: 'prog'),
      mock_tests.dataAnalysisTestData.toCore().copyWith(id: 'dtan'),
      mock_tests.uxDesignTestData.toCore().copyWith(id: 'hcev'),
      mock_tests.testingTestData.toCore().copyWith(id: 'test'),
    ]);
  }

  Stream<List<TestResultData>> getTestResultsForUser(String userId) {
    Timer.run(() => _testResultsController.add(List.unmodifiable(_testResults.where((r) => r.userId == userId))));
    return _testResultsController.stream;
  }

  Stream<List<CareerSimulationSession>> getSimulationSessionsForUser(String userId) {
    Timer.run(() => _sessionsController.add(List.unmodifiable(_sessions.where((s) => s.userId == userId))));
    return _sessionsController.stream;
  }

  Stream<List<MiniProject>> getMiniProjects() {
    return Stream.value([]);
  }

  Stream<List<ChatMessage>> getChatMessages(String sessionId) {
    final controller = _chatControllers.putIfAbsent(sessionId, () => StreamController<List<ChatMessage>>.broadcast());
    
    if (!_sessionMessages.containsKey(sessionId)) {
      _sessionMessages[sessionId] = [];
      ref.read(apiServiceProvider).getSimulationDetails(sessionId).then((data) {
        final List<dynamic> msgs = data['messages'] ?? [];
        final parsed = msgs.map((m) => ChatMessage(
          id: m['id']?.toString() ?? '',
          sender: m['sender'] ?? 'ai',
          text: m['text'] ?? '',
          timestamp: m['created_at'] != null ? DateTime.parse(m['created_at']) : DateTime.now(),
        )).toList();
        _sessionMessages[sessionId] = parsed;
        controller.add(List.unmodifiable(parsed));
      }).catchError((e) {
        // Ignored
      });
    }

    Timer.run(() => controller.add(List.unmodifiable(_sessionMessages[sessionId]!)));
    return controller.stream;
  }

  Future<void> saveTestResult(TestResultData result) async {
    final res = result.copyWith(id: result.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : result.id);
    _testResults.add(res);
    _testResultsController.add(List.unmodifiable(_testResults));
  }

  Future<String> createSimulationSession(CareerSimulationSession session) async {
    final newId = session.id.isNotEmpty ? session.id : DateTime.now().millisecondsSinceEpoch.toString();
    final newSession = session.copyWith(id: newId);
    _sessions.add(newSession);
    _sessionsController.add(List.unmodifiable(_sessions));
    return newId;
  }

  /// Synchronous snapshot of the messages currently stored for a session.
  /// Used to build conversation history for the LLM without awaiting the stream.
  List<ChatMessage> getSessionMessagesSync(String sessionId) {
    return List.unmodifiable(_sessionMessages[sessionId] ?? const []);
  }

  Future<void> addChatMessage(String sessionId, ChatMessage message) async {
    final messages = _sessionMessages[sessionId] ??= [];
    final msg = message.copyWith(id: message.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : message.id);
    messages.add(msg);
    if (_chatControllers.containsKey(sessionId)) {
      _chatControllers[sessionId]!.add(List.unmodifiable(messages));
    }
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    if (data.containsKey('skills')) {
      final user = ref.read(userProfileProvider).value;
      if (user != null) {
        final updatedUser = user.copyWith(
          skills: Map<String, double>.from(data['skills']),
        );
        ref.read(userProfileProvider.notifier).setUser(updatedUser);
      }
    }
  }
}
