import { CvScreeningRepository } from "../repositories/cv-screening.repository";
import { UserRepository as RepoUser } from "../repositories/user.repository";
import { CvScreening, CreateCvScreeningDTO } from "../types/cv-screening.types";
import { callAI } from "../utils/ai-client";
import fs from "fs";
import path from "path";
import mammoth from "mammoth";
async function extractPdfText(dataBuffer: Buffer): Promise<string> {
  try {
    const pdfModule = require("pdf-parse");
    let fn = pdfModule;

    if (typeof fn !== "function") {
      if (typeof fn?.default === "function") {
        fn = fn.default;
      } else if (typeof fn?.pdfParse === "function") {
        fn = fn.pdfParse;
      }
    }

    if (typeof fn === "function") {
      const parsed = await fn(dataBuffer);
      if (parsed && typeof parsed.text === "string" && parsed.text.trim().length > 0) {
        return parsed.text.trim();
      }
    }

    if (typeof pdfModule?.PDFParse === "function") {
      const parserInstance = new pdfModule.PDFParse({ data: dataBuffer });
      if (typeof parserInstance.getText === "function") {
        const textResult = await parserInstance.getText();
        if (textResult && typeof textResult.text === "string") {
          return textResult.text.trim();
        }
      }
    }
  } catch (err: any) {
    console.warn(`[CvScreening] extractPdfText error:`, err?.message || err);
  }
  return "";
}

export class CvScreeningService {
  private cvScreeningRepository = new CvScreeningRepository();
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

  async uploadAndAnalyze(userId: string, fileName: string, fileUrl: string): Promise<CvScreening> {
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

    let cvText = "";
    let base64Image: string | undefined;

    try {
      const cleanFilename = fileUrl.split("/uploads/").pop() || fileUrl;
      const filePath = path.join(process.cwd(), "uploads", cleanFilename);
      
      console.log(`[CvScreening] Looking for file on disk: ${filePath}`);
      if (fs.existsSync(filePath)) {
        console.log(`[CvScreening] Processing file ${fileName}...`);
        const fileExt = path.extname(fileName).toLowerCase();
        
        if ([".jpg", ".jpeg", ".png", ".webp"].includes(fileExt)) {
          const dataBuffer = fs.readFileSync(filePath);
          const mimeType = fileExt === ".jpg" || fileExt === ".jpeg" ? "jpeg" : fileExt.replace(".", "");
          base64Image = `data:image/${mimeType};base64,${dataBuffer.toString("base64")}`;
          cvText = "CV provided as an image.";
        } else if (fileExt === ".pdf") {
          const dataBuffer = fs.readFileSync(filePath);
          cvText = await extractPdfText(dataBuffer);
          console.log(`[CvScreening] PDF parsed successfully (${cvText.length} chars).`);
          if (cvText.length < 20) {
            console.log(`[CvScreening] PDF text length short/scanned. Using document filename and context.`);
            cvText = `Document uploaded: ${fileName}. Candidate: ${name}, Target Role: ${targetRole}. Please analyze this candidate CV file.`;
          }
        } else if (fileExt === ".docx") {
          const result = await mammoth.extractRawText({ path: filePath });
          cvText = result.value;
        } else {
          cvText = fs.readFileSync(filePath, "utf-8");
        }
        
        if (cvText.length > 15000) {
          cvText = cvText.substring(0, 15000) + "... (truncated)";
        }
        
        console.log(`[CvScreening] Successfully processed file.`);
      }
    } catch (err) {
      console.warn("[CvScreening] Failed to extract/read file:", err);
      cvText = "Could not extract text from the file.";
    }

    let analysisResult: any;
    let lastError = "";

    const systemPrompt = `You are an expert HR Specialist and professional ATS (Applicant Tracking System) CV screening assistant. Your primary job is to strictly validate whether the provided document is a genuine CV/Resume and evaluate its contents accurately. If the document is NOT a CV, is blank, or contains no readable CV section (skills, experience, education), you MUST fail the document with a low score (0 to 15).`;

    const userPrompt = `
Analyze the candidate's official CV document attached below and generate a professional ATS screening analysis:

CANDIDATE CONTEXT:
Name: ${name}
Target Role: ${targetRole}
Graduation Year / Status: ${graduationYear}
CV File Name: ${fileName}

--- CV CONTENT START ---
${cvText}
--- CV CONTENT END ---

CRITICAL VALIDATION INSTRUCTION:
1. FIRST, check if this document actually contains readable CV data (education, skills, projects, or work experience).
2. IF THE DOCUMENT IS EMPTY, BLANK, UNREADABLE, OR NOT A CV:
   - YOU MUST SET "overall_score" TO AN INTEGER BETWEEN 0 AND 15 (Critical failure).
   - In "ai_summary", explicitly state: "The uploaded file does not contain a valid or readable CV. Please upload a legitimate resume document containing your education, technical skills, and project experience."
   - In "strengths", list: ["No valid CV content detected", "Unable to verify education or skills"].
   - In "weaknesses", list: ["Uploaded document is unreadable or empty", "Missing technical skills and project history"].
3. IF THE DOCUMENT IS A VALID CV:
   - Extract actual University name, Major, Skills, Projects, and Work/Internship experiences directly from the document. Do NOT guess "UI" or default placeholders unless written in the CV.
   - Evaluate objectively based on ATS standards (0-100 score). Give high scores (75-98) ONLY when real technical skills (Flutter, React, PBO, MySQL, Git) and project evidence are present.

Return a JSON object containing EXACTLY these fields:
1. "overall_score": integer (0 to 15 for invalid/empty files; 60 to 98 for valid CVs)
2. "strengths": array of 3-5 specific strings
3. "weaknesses": array of 3-5 constructive growth areas
4. "ai_summary": string (3-4 sentences summarizing their profile or stating file invalidity)
5. "recommendations": array of 3-5 actionable steps to upload or polish the CV.

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
        console.warn(`[CvScreening] JSON parse failed: ${err.message}`);
        lastError = err.message;
      }
    }

    if (!analysisResult) {
      throw new Error(`AI Analysis failed for all available models. Please try again later. Last error: ${lastError}`);
    }

    // 4. Save to Database
    const screeningData: CreateCvScreeningDTO = {
      user_id: userId,
      file_name: fileName,
      file_url: fileUrl,
      overall_score: analysisResult.overall_score || 70,
      strengths: analysisResult.strengths || [],
      weaknesses: analysisResult.weaknesses || [],
      ai_summary: analysisResult.ai_summary || "Profile analysis completed successfully.",
      recommendations: analysisResult.recommendations || []
    };

    const created = await this.cvScreeningRepository.create(screeningData);

    // Fold the CV analysis into the user's overall readiness score so it
    // reflects more than just the skill assessment.
    try {
      await this.userRepository.recomputeReadinessScore(userId);
    } catch (err) {
      console.warn("[CvScreening] Failed to recompute readiness score:", err);
    }

    return created;
  }

  async getHistory(userId: string): Promise<CvScreening[]> {
    return await this.cvScreeningRepository.findAllByUserId(userId);
  }

  async getById(userId: string, id: string): Promise<CvScreening | null> {
    return await this.cvScreeningRepository.findById(id, userId);
  }

  async deleteScreening(userId: string, id: string): Promise<boolean> {
    // 1. Get screening record to find the file URL
    const screening = await this.cvScreeningRepository.findById(id, userId);
    if (!screening) {
      return false;
    }

    // 2. Delete file physical copy if it's on local disk
    try {
      if (screening.file_url && !screening.file_url.startsWith("http")) {
        // Construct the full local file path
        // Assume file_url looks like "uploads/filename.pdf" or "/uploads/filename.pdf"
        const cleanPath = screening.file_url.replace(/^\/?uploads\//, "");
        const filePath = path.join(process.cwd(), "uploads", cleanPath);
        
        if (fs.existsSync(filePath)) {
          fs.unlinkSync(filePath);
          console.log(`Deleted CV file at: ${filePath}`);
        }
      }
    } catch (err) {
      console.error("Failed to delete physical CV file:", err);
    }

    // 3. Delete from database
    return await this.cvScreeningRepository.deleteById(id, userId);
  }
}
