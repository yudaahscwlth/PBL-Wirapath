import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wirapath/features/simulation/data/services/job_analysis_api_service.dart';

void main() {
  test('JobAnalysisApiService retrieves skills prediction', () async {
    final mockClient = MockClient((request) async {
      final requestBody = jsonDecode(request.body);
      final jobTitle = requestBody['job_title'] ?? 'Frontend Developer';
      final topK = requestBody['top_k'] ?? 5;

      final responseBody = {
        'status': 'success',
        'job_title': jobTitle,
        'skills': List.generate(topK, (index) => {
          'skill': 'Skill $index',
          'confidence': 0.9 - (index * 0.1),
          'confidence_pct': (0.9 - (index * 0.1)) * 100,
        }),
      };

      return http.Response(jsonEncode(responseBody), 200, headers: {
        'content-type': 'application/json',
      });
    });

    final service = JobAnalysisApiService(client: mockClient);
    
    // Query API
    final response = await service.predictRequiredSkills('Frontend Developer', topK: 5);
    
    // Assert response content
    expect(response.jobTitle, equals('Frontend Developer'));
    expect(response.status, equals('success'));
    expect(response.skills, isNotEmpty);
    expect(response.skills.length, equals(5));
    
    // Check first skill structure
    final firstSkill = response.skills.first;
    expect(firstSkill.skill, isNotEmpty);
    expect(firstSkill.confidence, greaterThan(0.0));
    expect(firstSkill.confidencePct, greaterThan(0.0));
  });
}
