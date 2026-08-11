import { TranscriptScreeningRepository } from "../repositories/transcript-screening.repository";
import { UserRepository as RepoUser } from "../repositories/user.repository";
import { TranscriptScreening, CreateTranscriptScreeningDTO } from "../types/transcript-screening.types";
import { callAI } from "../utils/ai-client";
import fs from "fs";
import path from "path";
import { PDFParse } from "pdf-parse";
import mammoth from "mammoth";

export class TranscriptScreeningService {
  private transcriptScreeningRepository = new TranscriptScreeningRepository();
  private userRepository = new RepoUser();

  private extractJson(text: string): any {
    try {
      return JSON.parse(text);
    } catch (e) {
      const match = text.match(/```json\s*([\s\S]*?)\s*```/) || text.match(/```\s*([\s\S]*?)\s*```/);
      if (match && match[1]) {
        try {
          return JSON.parse(match[1].trim());
        } catch (e2) {}
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



  async uploadAndAnalyze(userId: string, fileName: string, fileUrl: string): Promise<TranscriptScreening> {
    // 1. Fetch user profile to tailor analysis
    const user = await this.userRepository.findById(userId);
    if (!user) {
      throw new Error("User not found");
    }

    const firstName = user.first_name || "Candidate";
    const lastName = user.last_name || "";
    const name = `${firstName} ${lastName}`.trim();
    const university = user.university || "University";
    const fieldOfStudy = user.field_of_study || "Computer Science";
    const targetRole = user.target_role || "Software Developer";
    const graduationYear = user.graduation_year || "N/A";

    let transcriptText = "";
    let base64Image: string | undefined;

    try {
      const cleanFilename = fileUrl.split("/uploads/").pop() || fileUrl;
      const filePath = path.join(process.cwd(), "uploads", cleanFilename);
      
      if (fs.existsSync(filePath)) {
        console.log(`[TranscriptScreening] Processing file ${fileName}...`);
        const fileExt = path.extname(fileName).toLowerCase();
        
        if ([".jpg", ".jpeg", ".png", ".webp"].includes(fileExt)) {
          const dataBuffer = fs.readFileSync(filePath);
          const mimeType = fileExt === ".jpg" || fileExt === ".jpeg" ? "jpeg" : fileExt.replace(".", "");
          base64Image = `data:image/${mimeType};base64,${dataBuffer.toString("base64")}`;
          transcriptText = "Transcript provided as an image.";
        } else if (fileExt === ".pdf") {
          const dataBuffer = fs.readFileSync(filePath);
          try {
            const pdfData = await new PDFParse({ data: dataBuffer }).getText();
            transcriptText = pdfData.text ? pdfData.text.trim() : "";
          } catch (e) {
            transcriptText = "";
          }
          // Fallback for scanned PDF / image-based PDF: pass base64 to vision model
          if (transcriptText.length < 50) {
            console.log(`[TranscriptScreening] PDF has no digital text layer (scanned PDF). Falling back to Vision Base64...`);
            base64Image = `data:application/pdf;base64,${dataBuffer.toString("base64")}`;
            transcriptText = "Transcript document provided as a scanned PDF / image file. Please read the document visually.";
          }
        } else if (fileExt === ".docx") {
          const result = await mammoth.extractRawText({ path: filePath });
          transcriptText = result.value;
        } else {
          transcriptText = fs.readFileSync(filePath, "utf-8");
        }
        
        if (transcriptText.length > 15000) {
          transcriptText = transcriptText.substring(0, 15000) + "... (truncated)";
        }
        
        console.log(`[TranscriptScreening] Successfully processed file.`);
      }
    } catch (err) {
      console.warn("[TranscriptScreening] Failed to extract/read file:", err);
      transcriptText = "Could not extract text from the file.";
    }

    let analysisResult: any;
    let lastError = "";

    const systemPrompt = `You are an expert Academic Advisor and technical recruiting assistant. Your task is to carefully analyze the candidate's actual academic transcript document (text/image) and evaluate their academic performance, GPA, university name, and specific course grades accurately against their target role. Do NOT use placeholder university names if a specific university (e.g., Politeknik Negeri Batam) is present in the transcript.`;

    const userPrompt = `
Analyze the candidate's official academic transcript document attached below and generate an accurate screening analysis:

CANDIDATE CONTEXT:
Name: ${name}
Target Role: ${targetRole}
Graduation Year / Status: ${graduationYear}
Transcript File Name: ${fileName}

--- TRANSCRIPT CONTENT START ---
${transcriptText}
--- TRANSCRIPT CONTENT END ---

INSTRUCTIONS:
1. Extract the actual University/Institution name, Major/Program of Study, and Cumulative GPA (IPK) directly from the transcript (e.g., Politeknik Negeri Batam - Teknik Informatika, IPK 3.91 / Cum Laude).
2. FOCUS STRICTLY ON GENERAL ACADEMIC EVALUATION:
   - Overall Cumulative GPA (IPK) and Academic Distinction (e.g., Cum Laude).
   - Academic Consistency & Grade Distribution (abundance of Grade A and A- across semesters).
   - Core Computer Science / Informatics Foundational Performance (Algorithms, Programming, Databases, Mathematics, HCI).
3. DO NOT evaluate industry-specific frameworks, tools, or libraries (such as React, Vue, State Management, or specific UI design tools). Technical skill depth is evaluated separately via CV Screening and Code Repositories, NOT in academic transcripts.
4. Evaluation Rubric (Total 100 points):
   - Academic Distinction & GPA (50 pts): High Cumulative GPA (e.g. 3.91 / Cum Laude).
   - Grade Consistency & Distinction (30 pts): Consistent high grades (A / A-) across academic semesters.
   - Core Academic Foundation (20 pts): Strong performance in core informatics coursework.
5. If the candidate has a high GPA (e.g., above 3.50 or Cum Laude) and consistent top grades (A/A-), AWARD A HIGH OVERALL SCORE (88 - 98).

Return a JSON object containing EXACTLY these fields:
1. "overall_score": integer between 0 and 100 (Give 88-98 for GPA > 3.5 or Cum Laude)
2. "strengths": array of 3-5 specific academic strengths highlighting high GPA, Cum Laude status, and academic consistency across semesters.
3. "weaknesses": array of 3-5 general academic growth areas (e.g. continuing academic rigor in upcoming upper-level research or capstone projects).
4. "ai_summary": string (3-4 sentences summarizing their overall academic excellence, university background, GPA, and general academic preparation)
5. "recommendations": array of 3-5 general academic and capstone preparation steps.

IMPORTANT: Output ONLY valid JSON string values without raw markdown bold asterisks (**) inside JSON strings.`;

      const userMessage = base64Image
        ? [
            { type: "text", text: userPrompt },
            { type: "image_url", image_url: { url: base64Image } }
          ]
        : userPrompt;

      const content = await callAI({
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userMessage },
        ],
        timeoutMs: 20000,
        temperature: 0.1,
        topP: 0.9,
      });

      if (content) {
        try {
          analysisResult = this.extractJson(content);
        } catch (err: any) {
          lastError = err.message;
          console.warn(`[TranscriptScreening] JSON parse failed: ${err.message}`);
        }
      }

    if (!analysisResult) {
      throw new Error(`Layanan AI sedang sibuk atau tidak dapat dijangkau. Silakan coba lagi nanti. (Error: ${lastError || "AI service unreachable"})`);
    }

    // 4. Save to Database
    const screeningData: CreateTranscriptScreeningDTO = {
      user_id: userId,
      file_name: fileName,
      file_url: fileUrl,
      overall_score: analysisResult.overall_score || 70,
      strengths: analysisResult.strengths || [],
      weaknesses: analysisResult.weaknesses || [],
      ai_summary: analysisResult.ai_summary || "Academic transcript analysis completed successfully.",
      recommendations: analysisResult.recommendations || []
    };

    const created = await this.transcriptScreeningRepository.create(screeningData);

    // Fold the transcript analysis into the user's overall readiness score
    try {
      await this.userRepository.recomputeReadinessScore(userId);
    } catch (err) {
      console.warn("[TranscriptScreening] Failed to recompute readiness score:", err);
    }

    return created;
  }

  async getHistory(userId: string): Promise<TranscriptScreening[]> {
    return await this.transcriptScreeningRepository.findAllByUserId(userId);
  }

  async getById(userId: string, id: string): Promise<TranscriptScreening | null> {
    return await this.transcriptScreeningRepository.findById(id, userId);
  }

  async deleteScreening(userId: string, id: string): Promise<boolean> {
    const screening = await this.transcriptScreeningRepository.findById(id, userId);
    if (!screening) {
      return false;
    }

    try {
      if (screening.file_url && !screening.file_url.startsWith("http")) {
        const cleanPath = screening.file_url.replace(/^\/?uploads\//, "");
        const filePath = path.join(process.cwd(), "uploads", cleanPath);
        
        if (fs.existsSync(filePath)) {
          fs.unlinkSync(filePath);
          console.log(`Deleted transcript file at: ${filePath}`);
        }
      }
    } catch (err) {
      console.error("Failed to delete physical transcript file:", err);
    }

    return await this.transcriptScreeningRepository.deleteById(id, userId);
  }
}
