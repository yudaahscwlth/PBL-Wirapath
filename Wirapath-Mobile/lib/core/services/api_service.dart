import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/simulation/data/models/jobdesk_analysis_result.dart';
import '../models/transcript_screening_model.dart';

class ApiService {
  // VPS Production Base URL
  static final String baseUrl = 'https://api.wirapath.my.id';

  // VPS Production Frontend URL
  static final String frontendUrl = 'https://wirapath.my.id';

  MediaType? _getMediaType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'doc':
        return MediaType('application', 'msword');
      case 'docx':
        return MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document');
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'zip':
        return MediaType('application', 'zip');
      case 'rar':
        return MediaType('application', 'x-rar-compressed');
      default:
        return null;
    }
  }

  // In-memory storage for JWT cookies and tokens
  static String? _cookieHeader;
  static String? _accessToken;
  static String? _refreshToken;

  // SharedPreferences keys for persisting the session across reloads/restarts.
  static const String _kAccessTokenKey = 'wp_access_token';
  static const String _kRefreshTokenKey = 'wp_refresh_token';
  static const String _kCookieHeaderKey = 'wp_cookie_header';
  static bool _sessionRestored = false;

  /// Restore a previously persisted session into memory. Safe to call multiple
  /// times; only the first call hits storage. Without this the static tokens
  /// were lost on every web reload / app restart, causing "Invalid or expired
  /// access token" on the home/readiness screens.
  Future<void> restoreSession() async {
    if (_sessionRestored) return;
    _sessionRestored = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken ??= prefs.getString(_kAccessTokenKey);
      _refreshToken ??= prefs.getString(_kRefreshTokenKey);
      _cookieHeader ??= prefs.getString(_kCookieHeaderKey);
    } catch (e) {
      debugPrint('restoreSession error: $e');
    }
  }

  /// Persist the current in-memory session to storage.
  Future<void> _persistSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_accessToken != null) {
        await prefs.setString(_kAccessTokenKey, _accessToken!);
      }
      if (_refreshToken != null) {
        await prefs.setString(_kRefreshTokenKey, _refreshToken!);
      }
      if (_cookieHeader != null) {
        await prefs.setString(_kCookieHeaderKey, _cookieHeader!);
      }
    } catch (e) {
      debugPrint('persistSession error: $e');
    }
  }

  /// Manually set session tokens and persist them. 
  /// Useful for social logins handled outside of ApiService.
  Future<void> setSessionTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _persistSession();
  }

  Future<void> _clearPersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kAccessTokenKey);
      await prefs.remove(_kRefreshTokenKey);
      await prefs.remove(_kCookieHeaderKey);
    } catch (e) {
      debugPrint('clearPersistedSession error: $e');
    }
  }

  /// Helper for API requests headers
  Map<String, String> _getHeaders() {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    if (_cookieHeader != null) {
      headers['cookie'] = _cookieHeader!;
    }
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    // Synchronously attach stored language code preference if available
    try {
      SharedPreferences.getInstance().then((prefs) {
        final lang = prefs.getString('app_language');
        if (lang != null && lang.isNotEmpty) {
          headers['Accept-Language'] = lang;
        }
      });
    } catch (_) {}
    debugPrint('ApiService Headers: $headers');
    return headers;
  }

  /// Perform an HTTP GET with automatic token refresh on 401 Unauthorized.
  Future<http.Response> _getWithAutoRefresh(Uri url, {bool allowRefresh = true}) async {
    await restoreSession();
    final response = await http.get(url, headers: _getHeaders());
    if (response.statusCode == 401 && allowRefresh && _refreshToken != null) {
      try {
        debugPrint('401 encountered on $url. Attempting token refresh...');
        await refreshTokens();
        return await http.get(url, headers: _getHeaders());
      } catch (e) {
        debugPrint('Token refresh failed during $url: $e');
      }
    }
    return response;
  }

  /// Analyze a job description against the user's profile via the backend
  /// (`POST /api/jobdesk/analyze`). Mirrors the web `analyzeJobDescription`,
  /// so mobile and web share the same backend/LLM pipeline.
  Future<JobdeskAnalysisResult> analyzeJobDescription(String jobDescription) async {
    final url = Uri.parse('$baseUrl/api/jobdesk/analyze');
    debugPrint('API POST -> $url');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'job_description': jobDescription}),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final result = decoded['result'] ?? decoded;
        return JobdeskAnalysisResult.fromJson(
          Map<String, dynamic>.from(result as Map),
        );
      } else {
        throw Exception(
          decoded['message'] ?? 'Failed to analyze job description.',
        );
      }
    } catch (e) {
      debugPrint('AnalyzeJobDescription API Error: $e');
      rethrow;
    }
  }

  /// Register a new account
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/register');
    debugPrint('API POST -> $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 201) {
        _updateCookie(response);
        if (decoded['result'] != null && decoded['result']['tokens'] != null) {
          _accessToken = decoded['result']['tokens']['accessToken'];
          _refreshToken = decoded['result']['tokens']['refreshToken'];
        }
        unawaited(_persistSession());
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Failed to register account.');
      }
    } catch (e) {
      debugPrint('Registration API Error: $e');
      rethrow;
    }
  }

  /// Login with email or username
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    debugPrint('API POST -> $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': email.trim(),
          'password': password,
        }),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _updateCookie(response);
        if (decoded['result'] != null && decoded['result']['tokens'] != null) {
          _accessToken = decoded['result']['tokens']['accessToken'];
          _refreshToken = decoded['result']['tokens']['refreshToken'];
        }
        unawaited(_persistSession());
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Incorrect email or password.');
      }
    } catch (e) {
      debugPrint('Login API Error: $e');
      rethrow;
    }
  }

  /// Request a password-reset email for [email].
  ///
  /// The backend is expected to always respond 200 regardless of whether the
  /// address exists (so the UI cannot be used to enumerate accounts) and to
  /// send the reset email out of band. We surface a generic success either
  /// way; only network/5xx failures throw.
  Future<void> requestPasswordReset(String email) async {
    final url = Uri.parse('$baseUrl/api/auth/forgot-password');
    debugPrint('API POST -> $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim()}),
      );

      // 2xx (sent / accepted) and 404 (no such account) are both treated as
      // success so we never reveal whether the email is registered.
      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return;
      }
      if (response.statusCode == 404) {
        return;
      }

      String message = 'Could not send the reset email. Please try again.';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] is String) {
          message = decoded['message'] as String;
        }
      } catch (_) {
        // Non-JSON error body — keep the generic message.
      }
      throw Exception(message);
    } catch (e) {
      debugPrint('Forgot-password API Error: $e');
      rethrow;
    }
  }

  /// Login or Register with Google OAuth
  Future<Map<String, dynamic>> googleAuth({
    required String idToken,
    bool isSignUp = false,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/google');
    debugPrint('API POST -> $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
          'isSignUp': isSignUp,
        }),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _updateCookie(response);
        if (decoded['result'] != null && decoded['result']['tokens'] != null) {
          _accessToken = decoded['result']['tokens']['accessToken'];
          _refreshToken = decoded['result']['tokens']['refreshToken'];
        }
        unawaited(_persistSession());
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Failed to authenticate with Google.');
      }
    } catch (e) {
      debugPrint('Google Auth API Error: $e');
      rethrow;
    }
  }

  /// Refresh Session Tokens
  Future<Map<String, dynamic>> refreshTokens() async {
    final url = Uri.parse('$baseUrl/api/auth/refresh');
    debugPrint('API POST -> $url');

    final headers = _getHeaders();

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          if (_refreshToken != null) 'refreshToken': _refreshToken,
        }),
      );
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _updateCookie(response);
        if (decoded['result'] != null && decoded['result']['tokens'] != null) {
          _accessToken = decoded['result']['tokens']['accessToken'];
          _refreshToken = decoded['result']['tokens']['refreshToken'];
        }
        unawaited(_persistSession());
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Failed to refresh tokens. Please login again.');
      }
    } catch (e) {
      debugPrint('Refresh Token API Error: $e');
      rethrow;
    }
  }

  /// Get current session user profile
  Future<Map<String, dynamic>> getCurrentUser({bool allowRefresh = true}) async {
    // Make sure any persisted session is loaded before the first auth call.
    await restoreSession();

    final url = Uri.parse('$baseUrl/api/auth/me');
    debugPrint('API GET -> $url');

    final response = await http.get(url, headers: _getHeaders());
    final decoded = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return decoded;
    }

    // On an expired/invalid access token, try a one-shot refresh using the
    // persisted refresh token, then retry once. This keeps the session alive
    // across web reloads instead of surfacing "Invalid or expired access token".
    if (response.statusCode == 401 && allowRefresh && _refreshToken != null) {
      try {
        await refreshTokens();
        return await getCurrentUser(allowRefresh: false);
      } catch (e) {
        debugPrint('Token refresh during getCurrentUser failed: $e');
      }
    }

    throw Exception(decoded['message'] ?? 'Session expired or unauthorized.');
  }

  /// Update Onboarding Profile (Names, University, etc)
  Future<Map<String, dynamic>> updateOnboardingProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String university,
    required String fieldOfStudy,
    required String graduationYear,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/$userId/onboarding/profile');
    debugPrint('API PATCH -> $url');

    final headers = _getHeaders();

    try {
      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'university': university,
          'field_of_study': fieldOfStudy,
          'graduation_year': int.tryParse(graduationYear) ?? 0,
        }),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Failed to update profile.');
      }
    } catch (e) {
      debugPrint('UpdateOnboardingProfile API Error: $e');
      rethrow;
    }
  }

  /// Complete onboarding goal step
  Future<Map<String, dynamic>> updateOnboardingGoal({
    required String userId,
    required String goal,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/$userId/onboarding/goal');
    debugPrint('API PATCH -> $url');

    final headers = _getHeaders();

    try {
      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode({'achievement_goal': goal}),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Failed to update goal.');
      }
    } catch (e) {
      debugPrint('UpdateOnboardingGoal API Error: $e');
      rethrow;
    }
  }

  /// Complete onboarding role step
  Future<Map<String, dynamic>> updateOnboardingRole({
    required String userId,
    required String role,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/$userId/onboarding/role');
    debugPrint('API PATCH -> $url');

    final headers = _getHeaders();

    try {
      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode({'target_role': role}),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Failed to update target role.');
      }
    } catch (e) {
      debugPrint('UpdateOnboardingRole API Error: $e');
      rethrow;
    }
  }

  /// Helper to upload files via Multipart.
  /// On web the file must be passed as [bytes] (dart:io paths are unavailable);
  /// on mobile/desktop [filePath] also works.
  Future<Map<String, dynamic>> _uploadMultipart({
    required String path,
    required String fileKey,
    required String fileName,
    String? filePath,
    List<int>? bytes,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    debugPrint('API PATCH MULTIPART -> $url');

    final request = http.MultipartRequest('PATCH', url);

    if (_cookieHeader != null) {
      request.headers['cookie'] = _cookieHeader!;
    }
    if (_accessToken != null) {
      request.headers['Authorization'] = 'Bearer $_accessToken';
    }

    final http.MultipartFile file;
    if (kIsWeb) {
      if (bytes == null) {
        throw Exception('No file data bytes provided for Web upload.');
      }
      file = http.MultipartFile.fromBytes(
        fileKey,
        bytes,
        filename: fileName,
        contentType: _getMediaType(fileName),
      );
    } else {
      if (bytes != null) {
        file = http.MultipartFile.fromBytes(
          fileKey,
          bytes,
          filename: fileName,
          contentType: _getMediaType(fileName),
        );
      } else if (filePath != null) {
        file = await http.MultipartFile.fromPath(
          fileKey,
          filePath,
          filename: fileName,
        );
      } else {
        throw Exception('No file data provided.');
      }
    }
    request.files.add(file);

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Failed to upload document.');
      }
    } catch (e) {
      debugPrint('Multipart Upload Error: $e');
      rethrow;
    }
  }

  /// Upload onboarding CV file.
  /// On web pass [cvBytes]; on mobile/desktop [cvPath] also works.
  Future<Map<String, dynamic>> uploadOnboardingCv({
    required String userId,
    required String cvName,
    String? cvPath,
    List<int>? cvBytes,
  }) async {
    return _uploadMultipart(
      path: '/api/users/$userId/onboarding/cv',
      fileKey: 'cv',
      filePath: cvPath,
      bytes: cvBytes,
      fileName: cvName,
    );
  }

  /// Upload onboarding Transcript file.
  /// On web pass [transcriptBytes]; on mobile/desktop [transcriptPath] also works.
  Future<Map<String, dynamic>> uploadOnboardingTranscript({
    required String userId,
    required String transcriptName,
    String? transcriptPath,
    List<int>? transcriptBytes,
  }) async {
    return _uploadMultipart(
      path: '/api/users/$userId/onboarding/transcript',
      fileKey: 'transcript',
      filePath: transcriptPath,
      bytes: transcriptBytes,
      fileName: transcriptName,
    );
  }

  /// Upload a CV to the dedicated CV-screening endpoint and return the AI
  /// analysis result (overall_score, strengths, weaknesses, recommendations,
  /// ai_summary). Mirrors the web `POST /api/cv-screening/upload` flow.
  Future<Map<String, dynamic>> uploadCvScreening({
    required String fileName,
    String? filePath,
    List<int>? bytes,
  }) async {
    final url = Uri.parse('$baseUrl/api/cv-screening/upload');
    debugPrint('API POST MULTIPART -> $url');

    final request = http.MultipartRequest('POST', url);
    if (_cookieHeader != null) {
      request.headers['cookie'] = _cookieHeader!;
    }
    if (_accessToken != null) {
      request.headers['Authorization'] = 'Bearer $_accessToken';
    }

    final http.MultipartFile cvFile;
    if (kIsWeb) {
      if (bytes == null) {
        throw Exception('No file data bytes provided for Web upload.');
      }
      cvFile = http.MultipartFile.fromBytes(
        'cv',
        bytes,
        filename: fileName,
        contentType: _getMediaType(fileName),
      );
    } else {
      if (bytes != null) {
        cvFile = http.MultipartFile.fromBytes(
          'cv',
          bytes,
          filename: fileName,
          contentType: _getMediaType(fileName),
        );
      } else if (filePath != null) {
        cvFile = await http.MultipartFile.fromPath(
          'cv',
          filePath,
          filename: fileName,
        );
      } else {
        throw Exception('No file data provided.');
      }
    }
    request.files.add(cvFile);

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Backend wraps the analysis under `result`.
        return Map<String, dynamic>.from(decoded['result'] ?? decoded);
      } else {
        throw Exception(decoded['message'] ?? 'Failed to analyze CV.');
      }
    } catch (e) {
      debugPrint('CV Screening Upload Error: $e');
      rethrow;
    }
  }

  /// Get history of CV screenings
  Future<List<Map<String, dynamic>>> getCvScreeningHistory() async {
    final url = Uri.parse('$baseUrl/api/cv-screening/history');
    final response = await _getWithAutoRefresh(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> list = decoded['result'] ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  /// Complete Onboarding Status
  Future<Map<String, dynamic>> completeOnboarding({
    required String userId,
    String? githubId,
    String? githubUsername,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/$userId/onboarding/complete');
    debugPrint('API POST -> $url');

    final headers = _getHeaders();

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          if (githubId != null) 'githubId': githubId,
          if (githubUsername != null) 'githubUsername': githubUsername,
        }),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Failed to complete onboarding.');
      }
    } catch (e) {
      debugPrint('CompleteOnboarding API Error: $e');
      rethrow;
    }
  }

  /// Update Account Settings
  Future<Map<String, dynamic>> updateProfileSettings({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
    required String university,
    String? fieldOfStudy,
    String? graduationYear,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/$userId/profile');
    debugPrint('API PATCH -> $url');

    final headers = _getHeaders();

    try {
      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'university': university,
          if (fieldOfStudy != null) 'field_of_study': fieldOfStudy,
          if (graduationYear != null) 'graduation_year': graduationYear,
        }),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Failed to update account settings.');
      }
    } catch (e) {
      debugPrint('UpdateProfileSettings API Error: $e');
      rethrow;
    }
  }

  /// Get a user's full profile by id.
  /// Returns the user object including `github_username` and linked `providers`.
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final url = Uri.parse('$baseUrl/api/users/$userId');
    debugPrint('API GET -> $url');

    final headers = _getHeaders();

    try {
      final response = await http.get(url, headers: headers);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(decoded['result'] ?? decoded);
      } else {
        throw Exception(decoded['message'] ?? 'Failed to load user profile.');
      }
    } catch (e) {
      debugPrint('GetUserProfile API Error: $e');
      rethrow;
    }
  }

  /// Connect / sync a GitHub account by username.
  /// Calls POST /api/users/:id/github/sync which links the username, fetches the
  /// account's public repositories and recomputes the readiness score.
  Future<Map<String, dynamic>> connectGithub({
    required String userId,
    required String githubUsername,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/$userId/github/sync');
    debugPrint('API POST -> $url');

    final headers = _getHeaders();

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'githubUsername': githubUsername}),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(decoded['result'] ?? decoded);
      } else {
        throw Exception(
            decoded['message'] ?? 'Failed to connect GitHub account.');
      }
    } catch (e) {
      debugPrint('ConnectGithub API Error: $e');
      rethrow;
    }
  }

  /// Update Password
  Future<Map<String, dynamic>> updatePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/$userId/password');
    debugPrint('API PUT -> $url');

    final headers = _getHeaders();

    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Failed to update password.');
      }
    } catch (e) {
      debugPrint('UpdatePassword API Error: $e');
      rethrow;
    }
  }

  // ── Mini Projects APIs ───────────────────────────────────────────────────

  /// Fetch mini projects matched to user's role
  Future<List<dynamic>> fetchMiniProjects() async {
    final url = Uri.parse('$baseUrl/api/mini-projects');
    debugPrint('API GET -> $url');

    final headers = _getHeaders();

    try {
      final response = await http.get(url, headers: headers);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return decoded['result'] ?? decoded ?? [];
      } else {
        throw Exception(decoded['message'] ?? 'Failed to fetch mini projects.');
      }
    } catch (e) {
      debugPrint('FetchMiniProjects API Error: $e');
      rethrow;
    }
  }

  /// Fetch a single mini project's details and submissions
  Future<Map<String, dynamic>> fetchMiniProjectDetail(String id) async {
    final url = Uri.parse('$baseUrl/api/mini-projects/$id');
    debugPrint('API GET -> $url');

    final headers = _getHeaders();

    try {
      final response = await http.get(url, headers: headers);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return decoded['result'] ?? decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Failed to fetch project detail.');
      }
    } catch (e) {
      debugPrint('FetchMiniProjectDetail API Error: $e');
      rethrow;
    }
  }

  /// Start a mini project
  Future<Map<String, dynamic>> startMiniProject(String id) async {
    final url = Uri.parse('$baseUrl/api/mini-projects/$id/start');
    debugPrint('API POST -> $url');

    final headers = _getHeaders();

    try {
      final response = await http.post(url, headers: headers);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return decoded['result'] ?? decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Failed to start project.');
      }
    } catch (e) {
      debugPrint('StartMiniProject API Error: $e');
      rethrow;
    }
  }

  /// Submit a mini project file archive (ZIP/RAR).
  /// On web the file must be passed as [bytes] (dart:io paths are unavailable);
  /// on mobile/desktop either works.
  Future<Map<String, dynamic>> submitMiniProjectFile(
    String id,
    String? filePath,
    String fileName, {
    List<int>? bytes,
  }) async {
    final url = Uri.parse('$baseUrl/api/mini-projects/$id/submit');
    debugPrint('API POST MULTIPART -> $url');

    final request = http.MultipartRequest('POST', url);

    if (_cookieHeader != null) {
      request.headers['cookie'] = _cookieHeader!;
    }
    if (_accessToken != null) {
      request.headers['Authorization'] = 'Bearer $_accessToken';
    }

    final http.MultipartFile file;
    if (kIsWeb) {
      if (bytes == null) {
        throw Exception('No file data bytes provided for Web upload.');
      }
      file = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: _getMediaType(fileName),
      );
    } else {
      if (bytes != null) {
        file = http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: _getMediaType(fileName),
        );
      } else if (filePath != null) {
        file = await http.MultipartFile.fromPath(
          'file',
          filePath,
          filename: fileName,
        );
      } else {
        throw Exception('No file data provided.');
      }
    }
    request.files.add(file);

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return decoded['result'] ?? decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Failed to submit project file.');
      }
    } catch (e) {
      debugPrint('SubmitMiniProjectFile Error: $e');
      rethrow;
    }
  }

  /// Submit a mini project via GitHub repository URL
  Future<Map<String, dynamic>> submitMiniProjectGitHub(String id, String githubUrl) async {
    final url = Uri.parse('$baseUrl/api/mini-projects/$id/submit');
    debugPrint('API POST -> $url');

    final headers = _getHeaders();

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'github_url': githubUrl}),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return decoded['result'] ?? decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Failed to submit project via GitHub.');
      }
    } catch (e) {
      debugPrint('SubmitMiniProjectGitHub API Error: $e');
      rethrow;
    }
  }

  // ── Simulations APIs ─────────────────────────────────────────────────────

  /// Fetch all simulation history for the current user
  Future<List<dynamic>> getSimulations() async {
    final url = Uri.parse('$baseUrl/api/simulations');
    debugPrint('API GET -> $url');

    try {
      final response = await _getWithAutoRefresh(url);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (decoded['result'] as List<dynamic>?) ?? [];
      } else {
        throw Exception(decoded['message'] ?? 'Failed to get simulation history.');
      }
    } catch (e) {
      debugPrint('GetSimulations API Error: $e');
      rethrow;
    }
  }

  /// Start a new AI simulation session (recruiter or salary)
  Future<Map<String, dynamic>> startSimulation(
    String type, {
    String? companyName,
    String? role,
    String? scenario,
  }) async {
    final url = Uri.parse('$baseUrl/api/simulations/start');
    debugPrint('API POST -> $url');

    final headers = _getHeaders();

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'type': type,
          if (companyName != null) 'company_name': companyName,
          if (role != null) 'role': role,
          if (scenario != null) 'scenario': scenario,
        }),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return decoded['result'] ?? decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Failed to start simulation.');
      }
    } catch (e) {
      debugPrint('StartSimulation API Error: $e');
      rethrow;
    }
  }

  /// Send message to AI simulation session
  Future<Map<String, dynamic>> sendSimulationMessage(String simulationId, String text) async {
    final url = Uri.parse('$baseUrl/api/simulations/$simulationId/message');
    debugPrint('API POST -> $url');

    final headers = _getHeaders();

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'text': text}),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return decoded['result'] ?? decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Failed to send simulation message.');
      }
    } catch (e) {
      debugPrint('SendSimulationMessage API Error: $e');
      rethrow;
    }
  }

  /// End an AI simulation session and fetch the evaluation report
  Future<Map<String, dynamic>> endSimulation(String simulationId) async {
    final url = Uri.parse('$baseUrl/api/simulations/$simulationId/end');
    debugPrint('API POST -> $url');

    final headers = _getHeaders();

    try {
      final response = await http.post(url, headers: headers);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return decoded['result'] ?? decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Failed to end simulation.');
      }
    } catch (e) {
      debugPrint('EndSimulation API Error: $e');
      rethrow;
    }
  }

  /// Fetch simulation details and messages
  Future<Map<String, dynamic>> getSimulationDetails(String simulationId) async {
    final url = Uri.parse('$baseUrl/api/simulations/$simulationId');
    debugPrint('API GET -> $url');

    final headers = _getHeaders();

    try {
      final response = await http.get(url, headers: headers);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return decoded['result'] ?? decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Failed to get simulation details.');
      }
    } catch (e) {
      debugPrint('GetSimulationDetails API Error: $e');
      rethrow;
    }
  }

  // ── Dashboard / Analytics APIs ───────────────────────────────────────────

  /// Fetch dashboard summary (readiness score, streak, trend)
  Future<Map<String, dynamic>> getDashboardSummary() async {
    final url = Uri.parse('$baseUrl/api/dashboard/summary');
    debugPrint('API GET -> $url');

    try {
      final response = await _getWithAutoRefresh(url);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return decoded['result'] ?? decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Failed to get dashboard summary.');
      }
    } catch (e) {
      debugPrint('GetDashboardSummary API Error: $e');
      rethrow;
    }
  }

  /// Fetch skill gap analytics
  Future<List<dynamic>> getSkillGap() async {
    final url = Uri.parse('$baseUrl/api/readiness/skill-gap');
    debugPrint('API GET -> $url');

    try {
      final response = await _getWithAutoRefresh(url);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return decoded['result'] ?? decoded ?? [];
      } else {
        throw Exception(decoded['message'] ?? 'Failed to get skill gaps.');
      }
    } catch (e) {
      debugPrint('GetSkillGap API Error: $e');
      rethrow;
    }
  }

  /// Fetch assessment analytics (same source the web profile/readiness use).
  /// Returns { has_assessment, overall_score, skills_mapped, critical_gaps_count,
  /// strengths_count, categories: [{slug,name,score,required,gap,status,...}] }.
  Future<Map<String, dynamic>> getAssessmentAnalytics() async {
    final url = Uri.parse('$baseUrl/api/assessment/analytics');
    debugPrint('API GET -> $url');
    try {
      final response = await _getWithAutoRefresh(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final result = decoded['result'] ?? decoded;
        return Map<String, dynamic>.from(result as Map);
      } else {
        throw Exception(decoded['message'] ?? 'Failed to get analytics.');
      }
    } catch (e) {
      debugPrint('GetAssessmentAnalytics API Error: $e');
      rethrow;
    }
  }

  /// Fetch the role-mapped assessment questions (the same problem set the web
  /// initial test uses). Returns a list of categories, each with `questions`:
  /// [{ id, slug, name, questions: [{ id, question_type, question_text, options }] }].
  Future<List<dynamic>> getAssessmentQuestions() async {
    final url = Uri.parse('$baseUrl/api/assessment/questions');
    debugPrint('API GET -> $url');
    try {
      final response = await _getWithAutoRefresh(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return decoded['result'] ?? decoded ?? [];
      } else {
        throw Exception(decoded['message'] ?? 'Failed to load questions.');
      }
    } catch (e) {
      debugPrint('GetAssessmentQuestions API Error: $e');
      rethrow;
    }
  }

  /// Submit the initial test. [answers] is a list of
  /// { 'question_id': String, 'user_answer': String }. The backend grades it,
  /// records per-category scores and recomputes the overall readiness score —
  /// so callers MUST invalidate the dashboard/analytics providers afterward.
  Future<Map<String, dynamic>> submitAssessment(
    List<Map<String, String>> answers, {
    int timeTakenSeconds = 0,
  }) async {
    final url = Uri.parse('$baseUrl/api/assessment/submit');
    debugPrint('API POST -> $url');
    final headers = _getHeaders();
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'answers': answers,
          'time_taken_seconds': timeTakenSeconds,
        }),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(decoded['result'] ?? decoded);
      } else {
        throw Exception(decoded['message'] ?? 'Failed to submit assessment.');
      }
    } catch (e) {
      debugPrint('SubmitAssessment API Error: $e');
      rethrow;
    }
  }

  /// Fetch market demand (top-10 in-demand skills for the user's target role).
  Future<List<dynamic>> getMarketDemand() async {
    final url = Uri.parse('$baseUrl/api/readiness/market-demand');
    debugPrint('API GET -> $url');
    final headers = _getHeaders();
    try {
      final response = await http.get(url, headers: headers);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return decoded['result'] ?? decoded ?? [];
      } else {
        throw Exception(decoded['message'] ?? 'Failed to get market demand.');
      }
    } catch (e) {
      debugPrint('GetMarketDemand API Error: $e');
      rethrow;
    }
  }

  /// Logout and clear cookies
  Future<void> logout() async {
    final url = Uri.parse('$baseUrl/api/auth/logout');
    debugPrint('API POST -> $url');

    final headers = _getHeaders();

    try {
      await http.post(url, headers: headers);
    } catch (e) {
      debugPrint('Logout API Error: $e');
    } finally {
      _cookieHeader = null;
      _accessToken = null;
      _refreshToken = null;
      await _clearPersistedSession();
    }
  }

  /// Manually set session cookies (e.g. from mobile OAuth callback)
  void setSessionCookies({required String accessToken, required String refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _cookieHeader = 'access_token=$accessToken; refresh_token=$refreshToken';
    debugPrint('Manually Set Cookies: $_cookieHeader');
    unawaited(_persistSession());
  }

  /// Parse and save set-cookie headers
  void _updateCookie(http.Response response) {
    final String? rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      final List<String> validCookies = [];
      
      final parts = rawCookie.split(',');
      for (var part in parts) {
        final trimmed = part.trim();
        if (trimmed.isEmpty) continue;
        
        final cookiePair = trimmed.split(';').first.trim();
        if (cookiePair.startsWith('access_token=')) {
          _accessToken = cookiePair.substring('access_token='.length);
          validCookies.add(cookiePair);
        } else if (cookiePair.startsWith('refresh_token=')) {
          _refreshToken = cookiePair.substring('refresh_token='.length);
          validCookies.add(cookiePair);
        }
      }

      if (validCookies.isNotEmpty) {
        _cookieHeader = validCookies.join('; ');
        debugPrint('Saved Cookies: $_cookieHeader');
        unawaited(_persistSession());
      }
    }
  }
}
