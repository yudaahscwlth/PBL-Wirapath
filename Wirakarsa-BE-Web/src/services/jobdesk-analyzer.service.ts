import { UserRepository } from "../repositories/user.repository";
import { JobdeskAnalysisResult } from "../types/jobdesk-analyzer.types";
import { callAI } from "../utils/ai-client";

export class JobdeskAnalyzerService {
  private userRepository = new UserRepository();

  private extractJson(text: string): JobdeskAnalysisResult {
    try {
      return JSON.parse(text) as JobdeskAnalysisResult;
    } catch (e) {
      const match = text.match(/```json\s*([\s\S]*?)\s*```/) || text.match(/```\s*([\s\S]*?)\s*```/);
      if (match && match[1]) {
        try {
          return JSON.parse(match[1].trim()) as JobdeskAnalysisResult;
        } catch (_e2) {}
      }
      const firstBrace = text.indexOf("{");
      const lastBrace = text.lastIndexOf("}");
      if (firstBrace !== -1 && lastBrace !== -1 && lastBrace > firstBrace) {
        try {
          const jsonStr = text.substring(firstBrace, lastBrace + 1);
          let out = "";
          let inString = false;
          for (let i = 0; i < jsonStr.length; i++) {
            let char = jsonStr[i];
            if (char === '"' && (i === 0 || jsonStr[i - 1] !== '\\')) {
              inString = !inString;
            }
            if (inString && char === '\n') {
              out += '\\n';
            } else if (inString && char === '\r') {
              // skip
            } else {
              out += char;
            }
          }
          return JSON.parse(out);
        } catch (e3) {}
      }
      throw new Error("Could not parse JSON from AI response: " + text);
    }
  }

  async analyze(userId: string, jobDescription: string): Promise<JobdeskAnalysisResult> {
    const user = await this.userRepository.findById(userId);
    const targetRole = user?.target_role || "Software Developer";
    const fieldOfStudy = user?.field_of_study || "Computer Science";
    const name = `${user?.first_name || "Candidate"} ${user?.last_name || ""}`.trim();

    const systemPrompt = `You are an expert Career Advisor and AI Job Match Analyzer. Your task is to analyze how well a candidate's profile matches a given job description, and provide constructive feedback.`;

    const userPrompt = `
Analyze the match between the following candidate and the job description.
Candidate Name: ${name}
Target Role: ${targetRole}
Background: ${fieldOfStudy}

Job Description:
${jobDescription}

Return a detailed JSON object with exact ratings and analysis. Be constructive but professional.
The JSON object MUST contain exactly these fields:
1. "match_score": integer between 0 and 100
2. "matching_skills": array of strings (skills the candidate likely has based on their target role and background that are required by the job)
3. "missing_skills": array of strings (skills required by the job that the candidate is missing)
4. "recommendations": array of strings (3 actionable steps to improve their chances for this job)
5. "summary": string (a professional 2-3 sentence summary of the match analysis)

IMPORTANT: Output ONLY the valid JSON object. Do not include any explanations, introduction, markdown blocks, or other text outside the JSON.
`;

    let analysisResult: JobdeskAnalysisResult | null = null;

    const content = await callAI({
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userPrompt },
      ],
      timeoutMs: 20000,
    });

    if (content) {
      try {
        analysisResult = this.extractJson(content);
      } catch (parseErr) {
        console.warn("[JobdeskAnalyzer] JSON parse failed:", parseErr);
      }
    }

    if (!analysisResult) {
      throw new Error("Layanan AI sedang sibuk atau tidak dapat dijangkau. Silakan coba beberapa saat lagi.");
    }

    return {
      match_score: analysisResult.match_score || 0,
      matching_skills: analysisResult.matching_skills || [],
      missing_skills: analysisResult.missing_skills || [],
      recommendations: analysisResult.recommendations || [],
      summary: analysisResult.summary || "Analysis completed.",
    };
  }
}
