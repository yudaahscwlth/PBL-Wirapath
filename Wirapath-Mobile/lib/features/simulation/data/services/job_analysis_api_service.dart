import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/job_analysis_response.dart';

class JobAnalysisApiService {
  static const String _baseUrl = 'https://dianpurbow-wirakarsa.hf.space/predict';

  final http.Client _client;

  JobAnalysisApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Predicts the required skills for a given job title.
  /// [jobTitle] is the title of the job to analyze.
  /// [topK] is the number of predicted skills to return (default: 10).
  Future<JobAnalysisResponse> predictRequiredSkills(String jobTitle, {int topK = 10}) async {
    try {
      final response = await _client.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'job_title': jobTitle,
          'top_k': topK,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return JobAnalysisResponse.fromJson(data);
        } else {
          throw Exception(data['message'] ?? 'API responded with status: ${data['status']}');
        }
      } else {
        throw Exception('Failed to fetch job analysis details. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to Jobdesk Analyzer service: $e');
    }
  }
}
