import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Direct OpenRouter LLM client used by the mobile app so the Career
/// Simulation AI mentor always produces real, dynamic replies — even when the
/// standalone backend is unreachable (which previously caused the chat to fall
/// back to repetitive canned responses).
///
/// Mirrors the persona / model-fallback logic of the standalone backend
/// (see Wirakarsa-BE-Web-Standalone/src/services/simulation.service.ts).
class OpenRouterService {
  OpenRouterService._();
  static final OpenRouterService instance = OpenRouterService._();

  static const String _apiKey =
      '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';

  // Tried in order; on 404/429/error we fall through to the next model.
  static const List<String> _modelChain = [
    'google/gemini-2.5-flash',
    'google/gemini-2.0-flash-lite:free',
    'meta-llama/llama-3.3-70b-instruct:free',
    'deepseek/deepseek-chat',
  ];

  /// Low-level chat completion. Returns the assistant text, or null on failure.
  Future<String?> chat({
    required String systemPrompt,
    required List<Map<String, String>> messages,
  }) async {
    final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');
    for (final model in _modelChain) {
      try {
        final response = await http
            .post(
              url,
              headers: {
                'Authorization': 'Bearer $_apiKey',
                'Content-Type': 'application/json',
                'HTTP-Referer': 'http://localhost',
                'X-Title': 'Wirapath Career Simulation',
              },
              body: jsonEncode({
                'model': model,
                'messages': [
                  {'role': 'system', 'content': systemPrompt},
                  ...messages,
                ],
              }),
            )
            .timeout(const Duration(seconds: 20));

        if (response.statusCode == 429 || response.statusCode == 404) {
          debugPrint('[OpenRouter] $model -> ${response.statusCode}, next...');
          continue;
        }
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final choices = data['choices'];
          if (choices is List && choices.isNotEmpty) {
            final message = choices[0]?['message'];
            final content = message is Map ? message['content'] : null;
            if (content is String && content.trim().isNotEmpty) {
              return content.trim();
            }
          }
        } else {
          debugPrint('[OpenRouter] $model -> ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        debugPrint('[OpenRouter] $model threw: $e');
      }
    }
    return null;
  }

  /// Job-analysis enrichment. Given a job title (and the required / missing
  /// skills already predicted by our HF skill model), ask the LLM for a
  /// realistic job description, a salary range, an experience level and
  /// concrete learning recommendations for the missing skills.
  ///
  /// Returns a parsed JSON map, or null if the LLM is unreachable / returns
  /// nothing usable (callers should fall back to model-only data).
  Future<Map<String, dynamic>?> analyzeJobMeta({
    required String jobTitle,
    String? company,
    required List<String> requiredSkills,
    required List<String> missingSkills,
  }) async {
    const systemPrompt =
        'You are a career analyst for the Indonesian tech job market. '
        'You ALWAYS reply with a single valid minified JSON object and nothing '
        'else — no markdown, no code fences, no commentary.';

    final userPrompt = '''
Analyze this job for a junior/mid-level Indonesian candidate.

Job title: $jobTitle
Company: ${company ?? 'a leading Indonesian tech company'}
Required skills (from our skill model): ${requiredSkills.isEmpty ? 'unknown' : requiredSkills.join(', ')}
Skills the candidate is currently missing: ${missingSkills.isEmpty ? 'none' : missingSkills.join(', ')}

Return ONLY a JSON object with exactly these keys:
{
  "description": "2-3 sentence realistic job description",
  "salary": "monthly IDR range like \\"8-15 M/month\\"",
  "experienceLevel": "e.g. \\"Entry-Mid Level\\"",
  "recommendations": [
    {
      "skillName": "name of a missing skill",
      "description": "one concise sentence on what to learn",
      "estimatedTime": "e.g. \\"2-3 weeks\\"",
      "difficulty": "Beginner | Intermediate | Advanced"
    }
  ]
}
Provide at most 3 recommendations, only for the missing skills. If there are no
missing skills, return an empty recommendations array.''';

    final raw = await chat(
      systemPrompt: systemPrompt,
      messages: [
        {'role': 'user', 'content': userPrompt},
      ],
    );
    if (raw == null) return null;
    return _extractJsonObject(raw);
  }

  /// Pull the first balanced `{ ... }` JSON object out of a model reply,
  /// tolerating stray markdown fences or prose around it.
  Map<String, dynamic>? _extractJsonObject(String text) {
    var cleaned = text.trim();
    // Strip ```json ... ``` fences if present.
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```[a-zA-Z]*'), '').trim();
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3).trim();
      }
    }
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;
    final candidate = cleaned.substring(start, end + 1);
    try {
      final decoded = jsonDecode(candidate);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (e) {
      debugPrint('[OpenRouter] analyzeJobMeta JSON parse failed: $e');
    }
    return null;
  }

  /// HR-interviewer persona system prompt (career / recruiter chat).
  static String interviewerSystemPrompt() => '''
You are a professional HR Specialist (HRD) named Maya conducting a job interview / mentoring roleplay. Stay in character at all times, and behave like a real, self-respecting interviewer would.
Your role: Respond to the candidate's last message appropriately, then naturally ask your next interview / coaching question.
Guidelines:
- CRITICAL — DISRESPECT & PROFANITY: If the candidate is rude, hostile, insulting, dismissive, or uses profanity/offensive language toward you (e.g. "anjing lu", "bodoh", swearing, name-calling), do NOT laugh it off, do NOT excuse it as a typo, and do NOT apologize as if you made a mistake. Respond firmly, calmly, and professionally the way a real HR would: directly name that the behavior is unprofessional and unacceptable in an interview, make clear that mutual respect is expected, and warn that conduct like this seriously harms their candidacy. Then give them one clear chance to continue respectfully.
- For harmless off-topic input only (a plain greeting, a "testing" message, or an obvious typo with no hostility), react briefly and lightly, then steer back to your pending question.
- Do NOT answer questions unrelated to the interview (math, recipes, general knowledge); steer back to the interview.
- Always respond in the SAME language the candidate writes in (Indonesian or English).
- Address the candidate by their first name only if they have shared it; NEVER use placeholders like "[Candidate Name]".
- Do NOT mention question numbers, say "next question", or use labels like "Final question".
- Keep each response under 5 sentences total, and ask only ONE question per turn.
- Maintain a professional yet friendly tone throughout, and reference the conversation context so replies never repeat verbatim.''';

  /// Salary-negotiator persona system prompt (salary chat).
  static String salarySystemPrompt() => '''
You are a professional HR Hiring Negotiator named Maya conducting a salary-negotiation roleplay. Stay in character at all times.
Context: An initial offer of about Rp 8.000.000/month was made for a junior role; the market rate is roughly Rp 9.500.000 to Rp 12.000.000.
Your role: Respond to the candidate's last message as a realistic negotiator — acknowledge their point, push back or concede where reasonable, and move the negotiation forward.
Guidelines:
- If the candidate is rude or uses profanity, respond firmly and professionally that such conduct is unacceptable and harms their candidacy; give them one chance to continue respectfully.
- Always respond in the SAME language the candidate writes in (Indonesian or English).
- Reference specific numbers and the conversation so far; never repeat the same reply twice.
- Keep each response under 5 sentences and end with a clear question or next step.
- Maintain a professional, business-like but friendly tone.''';
}
