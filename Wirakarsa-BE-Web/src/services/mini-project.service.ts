import { query } from "../db/connection";
import { MiniProjectRepository } from "../repositories/mini-project.repository";
import { UserRepository } from "../repositories/user.repository";
import { 
  MiniProjectWithSubmission, 
  UserMiniProjectSubmission,
  CreateSubmissionDTO,
  UpdateSubmissionReviewDTO
} from "../types/mini-project.types";
import { callAI } from "../utils/ai-client";
import fs from "fs";
import path from "path";
import AdmZip from "adm-zip";
import { PDFParse } from "pdf-parse";
import mammoth from "mammoth";

export class MiniProjectService {
  private miniProjectRepository = new MiniProjectRepository();
  private userRepository = new UserRepository();

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

  private async extractFileContent(filePath: string, fileType: string): Promise<string> {
    try {
      if (!fs.existsSync(filePath)) {
        return "File not found on server.";
      }

      const ext = fileType.toLowerCase();

      if (ext === "zip") {
        const zip = new AdmZip(filePath);
        const zipEntries = zip.getEntries();
        let content = "";
        let count = 0;

        for (const entry of zipEntries) {
          if (entry.isDirectory) continue;
          
          const name = entry.entryName.toLowerCase();
          // Skip non-code and configuration/modules paths
          if (
            name.includes("node_modules/") || 
            name.includes(".git/") || 
            name.includes(".next/") ||
            name.includes("dist/") ||
            name.includes("build/") ||
            name.includes("package-lock.json") ||
            name.includes("pnpm-lock.yaml") ||
            name.includes("yarn.lock")
          ) {
            continue;
          }

          const fileExt = path.extname(name);
          const textExtensions = [".js", ".ts", ".jsx", ".tsx", ".html", ".css", ".py", ".java", ".cpp", ".c", ".h", ".cs", ".json", ".md", ".sql", ".txt"];
          
          if (textExtensions.includes(fileExt)) {
            content += `\n--- File: ${entry.entryName} ---\n`;
            // Limit each file size to 2KB to prevent exceeding LLM context window
            content += entry.getData().toString("utf8").substring(0, 2000) + "\n";
            count++;
            if (count >= 15) {
              content += "\n... [Remaining files truncated to conserve space] ...\n";
              break;
            }
          }
        }
        return content || "No readable code/text files found in the ZIP archive.";
      }

      if (ext === "pdf") {
        const dataBuffer = fs.readFileSync(filePath);
        const data = await new PDFParse({ data: dataBuffer }).getText();
        return data.text || "No readable text found in PDF.";
      }

      if (ext === "docx") {
        const result = await mammoth.extractRawText({ path: filePath });
        return result.value || "No readable text found in DOCX.";
      }

      // If it's a raw text file or code file directly uploaded
      if (["js", "ts", "py", "html", "css", "txt", "json", "md"].includes(ext)) {
        return fs.readFileSync(filePath, "utf8").substring(0, 30000);
      }

      return `Non-extractable file type: ${fileType}. AI will grade based on project details and target role expectations.`;
    } catch (error) {
      console.error("[MiniProjectService] Error extracting file content:", error);
      return `Error reading file: ${(error as Error).message}`;
    }
  }



  async getProjectsByRole(userId: string): Promise<MiniProjectWithSubmission[]> {
    const user = await this.userRepository.findById(userId);
    if (!user) {
      throw new Error("User not found");
    }

    const targetRole = user.target_role || "Frontend Developer";
    let projects = await this.miniProjectRepository.findProjectsByUserRole(userId, targetRole);
    if (projects.length > 0) {
      return projects;
    }

    // Role-based keyword fallback matching
    const r = targetRole.toLowerCase();
    let fallbackRole = "Frontend Developer";
    if (r.includes("ui") || r.includes("ux") || r.includes("design")) {
      fallbackRole = "UI/UX Designer";
    } else if (r.includes("mobile")) {
      fallbackRole = "Mobile Developer";
    } else if (r.includes("backend")) {
      fallbackRole = "Backend Developer";
    } else if (r.includes("fullstack")) {
      fallbackRole = "Fullstack Developer";
    } else if (r.includes("data") || r.includes("scientist")) {
      fallbackRole = "Data Scientist";
    }

    projects = await this.miniProjectRepository.findProjectsByUserRole(userId, fallbackRole);
    if (projects.length > 0) {
      return projects;
    }

    // Ultimate fallback so Dev Hub is never empty
    return await this.miniProjectRepository.findProjectsByUserRole(userId, "Frontend Developer");
  }

  async getProjectDetail(userId: string, projectId: string): Promise<{ project: MiniProjectWithSubmission | null; submission: UserMiniProjectSubmission | null }> {
    const project = await this.miniProjectRepository.findProjectById(projectId, userId);
    if (!project) {
      return { project: null, submission: null };
    }

    const submission = await this.miniProjectRepository.findSubmission(projectId, userId);
    return { project, submission };
  }

  private async ensureProjectExists(projectId: string): Promise<void> {
    const rows = await query<any[]>(`SELECT id FROM mini_projects WHERE id = ? LIMIT 1`, [projectId]);
    if (rows.length === 0) {
      const seeds: Record<string, any> = {
        'mp-ux-1': { title: 'Figma Design System & Auto Layout Library', description: 'Construct a scalable, responsive Figma design system incorporating Auto Layout, color design tokens, and interactive component variants.', difficulty: 'Intermediate', estimated_hours: 6, points: 160, tech_stack: '["Figma", "Design Systems", "Auto Layout"]', tasks: '["Create color and typography design token styles", "Build flexible Auto Layout button and card components", "Set up interactive component state variants (hover, active)"]', role: 'UI/UX Designer', priority: 1 },
        'mp-ux-2': { title: 'Mobile Usability Audit & Redesign', description: 'Perform a Nielsen Heuristic Usability Audit on a mobile app flow, identify accessibility friction points, and deliver a high-fi interactive prototype.', difficulty: 'Intermediate', estimated_hours: 5, points: 150, tech_stack: '["Figma", "Usability Testing", "WCAG"]', tasks: '["Document usability flaws using Nielsen 10 Heuristics", "Audit color contrast ratios against WCAG 2.1 AA standards", "Build interactive high-fidelity Figma prototype"]', role: 'UI/UX Designer', priority: 2 },
        'mp-ux-3': { title: 'User Research & Wireframing Flow', description: 'Conduct user interviews, construct target User Personas and Journey Maps, and map out low-fidelity wireframe user navigation flows.', difficulty: 'Intermediate', estimated_hours: 4, points: 130, tech_stack: '["User Research", "Wireframing", "Figma"]', tasks: '["Synthesize qualitative interview data into Personas", "Map out end-to-end User Journey Map", "Design low-fidelity wireframe navigation flows"]', role: 'UI/UX Designer', priority: 3 },
        'mp-mb-1': { title: 'Flutter Multi-Tab App with Riverpod', description: 'Develop a multi-tab mobile application using Flutter, declarative Go Router navigation, and Riverpod reactive state management.', difficulty: 'Intermediate', estimated_hours: 6, points: 160, tech_stack: '["Flutter", "Dart", "Riverpod", "Go Router"]', tasks: '["Create responsive multi-tab shell navigation", "Implement Riverpod AsyncNotifier for state management", "Design responsive mobile layout screens"]', role: 'Mobile Developer', priority: 1 },
        'mp-be-1': { title: 'Express REST API with JWT Auth', description: 'Design and deploy a secure Node.js Express REST API featuring bcrypt password hashing, JWT stateless authentication, and input validation.', difficulty: 'Intermediate', estimated_hours: 6, points: 150, tech_stack: '["Node.js", "Express", "JWT", "bcrypt"]', tasks: '["Set up auth registration and login endpoints", "Implement JWT token validation middleware", "Add Zod schema request validation"]', role: 'Backend Developer', priority: 1 },
        'mp-fe-1': { title: 'React E-Commerce Dashboard', description: 'Build a dynamic, responsive e-commerce management dashboard using React, Tailwind CSS, and custom hooks.', difficulty: 'Intermediate', estimated_hours: 6, points: 150, tech_stack: '["React", "Tailwind CSS", "TypeScript"]', tasks: '["Create responsive layout grid", "Implement dark mode theme switcher", "Build filterable product data table"]', role: 'Frontend Developer', priority: 1 }
      };

      const seed = seeds[projectId] || {
        title: 'Software Development Mini Project',
        description: 'Design and construct a software feature component.',
        difficulty: 'Intermediate',
        estimated_hours: 5,
        points: 150,
        tech_stack: '["TypeScript", "JavaScript"]',
        tasks: '["Implement feature core logic", "Write unit test validation", "Deploy application component"]',
        role: 'Frontend Developer',
        priority: 1
      };

      await query(
        `INSERT IGNORE INTO mini_projects (id, title, description, difficulty, estimated_hours, points, tech_stack, tasks, sort_order) 
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [projectId, seed.title, seed.description, seed.difficulty, seed.estimated_hours, seed.points, seed.tech_stack, seed.tasks, seed.priority]
      );

      await query(
        `INSERT IGNORE INTO mini_project_role_mapping (id, mini_project_id, target_role_pattern, priority) 
         VALUES (UUID(), ?, ?, ?)`,
        [projectId, seed.role, seed.priority]
      );
    }
  }

  async startProject(userId: string, projectId: string): Promise<UserMiniProjectSubmission> {
    await this.ensureProjectExists(projectId);
    const existing = await this.miniProjectRepository.findSubmission(projectId, userId);
    if (existing) {
      if (existing.status === 'not_started') {
        await this.miniProjectRepository.updateSubmission(existing.id, { status: 'in_progress' });
        existing.status = 'in_progress';
      }
      return existing;
    }

    const submissionData: CreateSubmissionDTO = {
      user_id: userId,
      mini_project_id: projectId,
      status: 'in_progress'
    };

    return await this.miniProjectRepository.createSubmission(submissionData);
  }

  async submitAndReview(userId: string, projectId: string, file: Express.Multer.File, lang: string = 'en'): Promise<UserMiniProjectSubmission> {
    await this.ensureProjectExists(projectId);
    // 1. Fetch user & project to check permissions & context
    const user = await this.userRepository.findById(userId);
    if (!user) {
      throw new Error(lang === 'id' ? "Pengguna tidak ditemukan" : "User not found");
    }

    const project = await this.miniProjectRepository.findProjectById(projectId, userId);
    if (!project) {
      throw new Error(lang === 'id' ? "Proyek tidak ditemukan" : "Project not found");
    }

    // 2. Build local file URL relative path
    const fileUrl = path.join("uploads", file.filename);
    const fileName = file.originalname;
    const fileType = path.extname(file.originalname).replace(".", "").toLowerCase();

    // 3. Create or Update submission status to 'submitted'
    let submission = await this.miniProjectRepository.findSubmission(projectId, userId);
    if (submission) {
      // delete old file if it exists locally to avoid junk clutter
      if (submission.file_url && !submission.file_url.startsWith("http")) {
        try {
          const oldFilePath = path.join(process.cwd(), submission.file_url);
          if (fs.existsSync(oldFilePath)) {
            fs.unlinkSync(oldFilePath);
          }
        } catch (err) {
          console.warn("Failed to delete old submission file:", err);
        }
      }

      await this.miniProjectRepository.updateSubmission(submission.id, {
        status: 'submitted',
        file_name: fileName,
        file_url: fileUrl,
        file_type: fileType,
        submitted_at: new Date()
      });
      submission.status = 'submitted';
      submission.file_name = fileName;
      submission.file_url = fileUrl;
      submission.file_type = fileType;
      submission.submitted_at = new Date();
    } else {
      submission = await this.miniProjectRepository.createSubmission({
        user_id: userId,
        mini_project_id: projectId,
        status: 'submitted',
        file_name: fileName,
        file_url: fileUrl,
        file_type: fileType,
        submitted_at: new Date()
      });
    }

    // 4. Extract content from the uploaded file
    const absoluteFilePath = path.join(process.cwd(), fileUrl);
    const extractedContent = await this.extractFileContent(absoluteFilePath, fileType);

    // 5. Trigger AI Review
    let reviewResult: any = null;
    const isId = lang.toLowerCase().startsWith('id');

    const evaluationCriteriaStr = JSON.stringify(project.evaluation_criteria || []);
    const relatedSkillsStr = JSON.stringify(project.related_skills || []);

    const userPrompt1 = isId
      ? `Lakukan review mendalam terhadap kode/berkas submission proyek berikut:
Judul Proyek: ${project.title}
Target Peran: ${user.target_role || "Developer"}
Keahlian Terkait: ${relatedSkillsStr}
Kriteria Evaluasi: ${evaluationCriteriaStr}

BERKAS BRIEF PROYEK:
---
${project.brief}
---

KODE/KONTEN SUBMISSION YANG DIEKSTRAK:
---
${extractedContent}
---

Tugas Anda adalah menilai submission ini secara objektif berdasarkan kriteria evaluasi dan brief proyek. Tulis seluruh feedback dalam BAHASA INDONESIA.
Kembalikan payload JSON yang valid dengan format berikut:
{
  "overall_score": <skor_keseluruhan_integer_antara_0_dan_100>,
  "strengths": ["<kelebihan_1>", "<kelebihan_2>", "<kelebihan_3>"],
  "improvements": ["<saran_perbaikan_1>", "<saran_perbaikan_2>", "<saran_perbaikan_3>"],
  "objectives_met": [
    { "title": "<kriteria_1>", "status": "success" },
    { "title": "<kriteria_2>", "status": "warning" }
  ],
  "ai_summary": "<ringkasan_review_menyeluruh_3_sampai_4_kalimat>"
}

Hanya kembalikan objek JSON yang valid.`
      : `Thoroughly review the candidate's submitted project files against the project brief:
Project Title: ${project.title}
Target Role: ${user.target_role || "Developer"}
Related Skills: ${relatedSkillsStr}
Evaluation Criteria: ${evaluationCriteriaStr}

PROJECT BRIEF CONTENT:
---
${project.brief}
---

EXTRACTED SUBMISSION CONTENT:
---
${extractedContent}
---

Your task is to objectively evaluate this submission based on the evaluation criteria and project brief. Write ALL feedback strictly in ENGLISH.
Return a valid JSON object matching this exact format:
{
  "overall_score": <overall_score_integer_between_0_and_100>,
  "strengths": ["<strength_1>", "<strength_2>", "<strength_3>"],
  "improvements": ["<improvement_1>", "<improvement_2>", "<improvement_3>"],
  "objectives_met": [
    { "title": "<criteria_1>", "status": "success" },
    { "title": "<criteria_2>", "status": "warning" }
  ],
  "ai_summary": "<comprehensive_review_summary_3_to_4_sentences>"
}

Output ONLY the valid JSON object.`;

    const aiContent1 = await callAI({
      messages: [
        {
          role: "system",
          content: `You are an expert Senior Technical Reviewer and Lead Engineer. ${
            isId
              ? "Output all feedback strictly in INDONESIAN language (Bahasa Indonesia)."
              : "Output all feedback strictly in ENGLISH language."
          }`
        },
        { role: "user", content: userPrompt1 }
      ],
      timeoutMs: 30000,
    });

    if (aiContent1) {
      try {
        reviewResult = this.extractJson(aiContent1);
      } catch (parseErr) {
        console.warn("[MiniProjectService] JSON parse failed:", parseErr);
      }
    }

    if (!reviewResult) {
      throw new Error("Layanan AI sedang sibuk atau tidak dapat dijangkau untuk mengevaluasi proyek ini. Silakan coba lagi nanti.");
    }

    // 6. Save AI review to Database
    const reviewData: UpdateSubmissionReviewDTO = {
      status: 'reviewed',
      overall_score: reviewResult.overall_score || 80,
      strengths: reviewResult.strengths || [],
      improvements: reviewResult.improvements || [],
      objectives_met: reviewResult.objectives_met || [],
      ai_summary: reviewResult.ai_summary || "Proyek telah berhasil dievaluasi.",
      reviewed_at: new Date()
    };

    const reviewed = await this.miniProjectRepository.updateSubmissionReview(submission.id, reviewData);
    // Reviewed Dev Hub work feeds the overall readiness score.
    await this.userRepository.recomputeReadinessScore(userId);
    return reviewed;
  }

  async submitGitHubAndReview(userId: string, projectId: string, githubUrl: string, lang: string = 'en'): Promise<UserMiniProjectSubmission> {
    const isId = lang.toLowerCase().startsWith('id');

    // 1. Fetch user & project to check permissions & context
    const user = await this.userRepository.findById(userId);
    if (!user) {
      throw new Error(isId ? "Pengguna tidak ditemukan" : "User not found");
    }

    const project = await this.miniProjectRepository.findProjectById(projectId, userId);
    if (!project) {
      throw new Error(isId ? "Proyek tidak ditemukan" : "Project not found");
    }

    // If URL is a Figma link or external non-GitHub design link, handle via Figma AI Design Reviewer
    if (githubUrl.includes("figma.com") || !githubUrl.includes("github.com")) {
      return await this.reviewFigmaLink(user, project, githubUrl, isId);
    }

    // 2. Parse owner and repo from githubUrl
    const match = githubUrl.match(/github\.com\/([^\/]+)\/([^\/\?#]+)/);
    if (!match) {
      return await this.reviewFigmaLink(user, project, githubUrl, isId);
    }
    const owner = match[1];
    const repo = match[2].replace(/\.git$/, "");

    // 3. Download the repository as a ZIP archive from GitHub API
    const zipUrl = `https://api.github.com/repos/${owner}/${repo}/zipball/main`;
    console.log(`[MiniProjectService] Downloading GitHub repo: ${owner}/${repo} from ${zipUrl}...`);

    let zipBuffer: ArrayBuffer;
    try {
      let response = await fetch(zipUrl, {
        headers: {
          "User-Agent": "Hi-Fi-Dev-Hub-Backend"
        }
      });

      // Try master branch if main returns 404
      if (response.status === 404) {
        const fallbackUrl = `https://api.github.com/repos/${owner}/${repo}/zipball/master`;
        console.log(`[MiniProjectService] ZIP main branch failed, trying master branch fallback: ${fallbackUrl}`);
        response = await fetch(fallbackUrl, {
          headers: {
            "User-Agent": "Hi-Fi-Dev-Hub-Backend"
          }
        });
      }

      if (!response.ok) {
        throw new Error(`GitHub API status ${response.status}: ${response.statusText}`);
      }

      zipBuffer = await response.arrayBuffer();
    } catch (err) {
      console.error("[MiniProjectService] Failed to download GitHub repo ZIP:", err);
      throw new Error(
        isId
          ? `Gagal mengunduh berkas dari GitHub. Pastikan repositori Anda Publik. Detail: ${(err as Error).message}`
          : `Failed to download repository files from GitHub. Please ensure your repository is Public. Detail: ${(err as Error).message}`
      );
    }

    // 4. Save to temporary file in uploads directory
    const tempFileName = `github-${owner}-${repo}-${Date.now()}.zip`;
    const tempFilePath = path.join(process.cwd(), "uploads", tempFileName);
    
    // Ensure uploads folder exists
    if (!fs.existsSync(path.dirname(tempFilePath))) {
      fs.mkdirSync(path.dirname(tempFilePath), { recursive: true });
    }

    fs.writeFileSync(tempFilePath, Buffer.from(zipBuffer));
    console.log(`[MiniProjectService] Saved GitHub ZIP to temporary path: ${tempFilePath}`);

    // 5. Create or Update submission status to 'submitted'
    const fileUrl = githubUrl;
    const fileName = `github:${owner}/${repo}`;
    const fileType = "github";

    let submission = await this.miniProjectRepository.findSubmission(projectId, userId);
    if (submission) {
      if (submission.file_url && !submission.file_url.startsWith("http") && !submission.file_url.includes("github.com")) {
        try {
          const oldFilePath = path.join(process.cwd(), submission.file_url);
          if (fs.existsSync(oldFilePath)) {
            fs.unlinkSync(oldFilePath);
          }
        } catch (err) {
          console.warn("Failed to delete old submission file:", err);
        }
      }

      await this.miniProjectRepository.updateSubmission(submission.id, {
        status: 'submitted',
        file_name: fileName,
        file_url: fileUrl,
        file_type: fileType,
        submitted_at: new Date()
      });
      submission.status = 'submitted';
      submission.file_name = fileName;
      submission.file_url = fileUrl;
      submission.file_type = fileType;
      submission.submitted_at = new Date();
    } else {
      submission = await this.miniProjectRepository.createSubmission({
        user_id: userId,
        mini_project_id: projectId,
        status: 'submitted',
        file_name: fileName,
        file_url: fileUrl,
        file_type: fileType,
        submitted_at: new Date()
      });
    }

    // 6. Extract content from the downloaded temporary ZIP file
    const extractedContent = await this.extractFileContent(tempFilePath, "zip");

    // 7. Delete temporary ZIP file to save disk space
    try {
      if (fs.existsSync(tempFilePath)) {
        fs.unlinkSync(tempFilePath);
        console.log(`[MiniProjectService] Cleaned up temporary ZIP: ${tempFilePath}`);
      }
    } catch (err) {
      console.warn("Failed to delete temporary ZIP file:", err);
    }

    // 8. Trigger AI Review
    let reviewResult: any = null;

    const evaluationCriteriaStr2 = JSON.stringify(project.evaluation_criteria || []);
    const relatedSkillsStr2 = JSON.stringify(project.related_skills || []);

    const userPrompt2 = isId
      ? `Lakukan review mendalam terhadap kode/berkas submission GitHub berikut:
Judul Proyek: ${project.title}
Target Peran: ${user.target_role || "Developer"}
Keahlian Terkait: ${relatedSkillsStr2}
Kriteria Evaluasi: ${evaluationCriteriaStr2}

BERKAS BRIEF PROYEK:
---
${project.brief}
---

KODE/KONTEN REPOSITORI GITHUB YANG DIEKSTRAK:
---
${extractedContent}
---

Tugas Anda adalah menilai submission ini secara objektif berdasarkan kriteria evaluasi dan brief proyek. Tulis seluruh feedback dalam BAHASA INDONESIA.
Kembalikan payload JSON yang valid dengan format berikut:
{
  "overall_score": <skor_keseluruhan_integer_antara_0_dan_100>,
  "strengths": ["<kelebihan_1>", "<kelebihan_2>", "<kelebihan_3>"],
  "improvements": ["<saran_perbaikan_1>", "<saran_perbaikan_2>", "<saran_perbaikan_3>"],
  "objectives_met": [
    { "title": "<kriteria_1>", "status": "success" },
    { "title": "<kriteria_2>", "status": "warning" }
  ],
  "ai_summary": "<ringkasan_review_menyeluruh_3_sampai_4_kalimat>"
}

Hanya kembalikan objek JSON yang valid.`
      : `Thoroughly review the candidate's submitted GitHub repository code against the project brief:
Project Title: ${project.title}
Target Role: ${user.target_role || "Developer"}
Related Skills: ${relatedSkillsStr2}
Evaluation Criteria: ${evaluationCriteriaStr2}

PROJECT BRIEF CONTENT:
---
${project.brief}
---

EXTRACTED GITHUB REPOSITORY CONTENT:
---
${extractedContent}
---

Your task is to objectively evaluate this submission based on the evaluation criteria and project brief. Write ALL feedback strictly in ENGLISH.
Return a valid JSON object matching this exact format:
{
  "overall_score": <overall_score_integer_between_0_and_100>,
  "strengths": ["<strength_1>", "<strength_2>", "<strength_3>"],
  "improvements": ["<improvement_1>", "<improvement_2>", "<improvement_3>"],
  "objectives_met": [
    { "title": "<criteria_1>", "status": "success" },
    { "title": "<criteria_2>", "status": "warning" }
  ],
  "ai_summary": "<comprehensive_review_summary_3_to_4_sentences>"
}

Output ONLY the valid JSON object.`;

    const aiContent2 = await callAI({
      messages: [
        {
          role: "system",
          content: `You are an expert Senior Technical Reviewer and Lead Engineer. ${
            isId
              ? "Output all feedback strictly in INDONESIAN language (Bahasa Indonesia)."
              : "Output all feedback strictly in ENGLISH language."
          }`
        },
        { role: "user", content: userPrompt2 }
      ],
      timeoutMs: 30000,
    });

    if (aiContent2) {
      try {
        reviewResult = this.extractJson(aiContent2);
      } catch (parseErr) {
        console.warn("[MiniProjectService] GitHub review JSON parse failed:", parseErr);
      }
    }

    if (!reviewResult) {
      throw new Error("Layanan AI sedang sibuk atau tidak dapat dijangkau untuk mengevaluasi repositori GitHub ini. Silakan coba lagi nanti.");
    }

    // 9. Save AI review to Database
    const reviewData: UpdateSubmissionReviewDTO = {
      status: 'reviewed',
      overall_score: reviewResult.overall_score || 80,
      strengths: reviewResult.strengths || [],
      improvements: reviewResult.improvements || [],
      objectives_met: reviewResult.objectives_met || [],
      ai_summary: reviewResult.ai_summary || "Proyek telah berhasil dievaluasi.",
      reviewed_at: new Date()
    };

    const reviewed = await this.miniProjectRepository.updateSubmissionReview(submission.id, reviewData);
    // Reviewed Dev Hub work feeds the overall readiness score.
    await this.userRepository.recomputeReadinessScore(userId);
    return reviewed;
  }

  private parseFigmaFileKey(figmaUrl: string): string | null {
    const match = figmaUrl.match(/figma\.com\/(?:file|design|proto)\/([a-zA-Z0-9]+)/i);
    return match ? match[1] : null;
  }

  private async reviewFigmaLink(user: any, project: any, figmaUrl: string, isId: boolean): Promise<UserMiniProjectSubmission> {
    // 1. Verify Figma URL format & extract file key
    const fileKey = this.parseFigmaFileKey(figmaUrl);
    if (!fileKey) {
      throw new Error(
        isId
          ? "Format URL Figma tidak valid. Gunakan link resmi Figma (contoh: https://www.figma.com/design/abcdef12345/Judul-Proyek)."
          : "Invalid Figma URL format. Please use an official Figma share link (e.g., https://www.figma.com/design/abcdef12345/Project-Name)."
      );
    }

    // 2. Perform live verification & optional Figma REST API metadata extraction
    let figmaMetadataStr = `Figma Share Link: ${figmaUrl}\nFigma File Key: ${fileKey}`;
    let isLiveFetched = false;

    const figmaToken = process.env.FIGMA_ACCESS_TOKEN || process.env.FIGMA_API_KEY;
    if (figmaToken) {
      try {
        const res = await fetch(`https://api.figma.com/v1/files/${fileKey}`, {
          headers: { "X-Figma-Token": figmaToken }
        });

        if (res.status === 404) {
          throw new Error(
            isId
              ? "File desain Figma tidak ditemukan (404). Silakan periksa kembali link Anda."
              : "Figma design file not found (404)."
          );
        }
        if (res.status === 403) {
          throw new Error(
            isId
              ? "Akses ke file Figma ditolak (403). Pastikan akses file diatur ke 'Anyone with the link can view'."
              : "Figma access denied (403). Please set share access to 'Anyone with the link can view'."
          );
        }

        if (res.ok) {
          const figmaData: any = await res.json();
          const docPages = (figmaData.document?.children || []).map((p: any) => p.name).join(", ");
          const componentsCount = Object.keys(figmaData.components || {}).length;
          const stylesCount = Object.keys(figmaData.styles || {}).length;

          figmaMetadataStr = `
Judul File Figma: ${figmaData.name}
Terakhir Diperbarui: ${figmaData.lastModified}
Versi Dokumen: ${figmaData.version}
Daftar Halaman/Canvases: ${docPages || "Default Canvas"}
Jumlah Komponen Varian: ${componentsCount}
Jumlah Design Tokens / Styles: ${stylesCount}
Figma Share Link: ${figmaUrl}
`;
          isLiveFetched = true;
        }
      } catch (err: any) {
        if (err.message && (err.message.includes("404") || err.message.includes("403"))) {
          throw err;
        }
        console.warn("[MiniProjectService] Figma REST API fetch failed, proceeding with URL verification:", err);
      }
    }

    // If Figma token not present, perform basic URL reachability check
    if (!isLiveFetched) {
      try {
        const checkRes = await fetch(figmaUrl, { method: "HEAD" });
        if (checkRes.status === 404) {
          throw new Error(
            isId
              ? "Link Figma tidak dapat ditemukan (404 Not Found). Silakan periksa kembali URL Anda."
              : "Figma link not found (404 Not Found)."
          );
        }
      } catch (err: any) {
        if (err.message && err.message.includes("404")) throw err;
      }
    }

    // 3. Upsert submission state
    let submission = await this.miniProjectRepository.findSubmission(project.id, user.id);
    if (submission) {
      await this.miniProjectRepository.updateSubmission(submission.id, {
        status: 'submitted',
        file_name: figmaUrl,
        file_url: figmaUrl,
        file_type: 'figma',
        submitted_at: new Date()
      });
      submission.status = 'submitted';
      submission.file_name = figmaUrl;
      submission.file_url = figmaUrl;
      submission.file_type = 'figma';
    } else {
      submission = await this.miniProjectRepository.createSubmission({
        user_id: user.id,
        mini_project_id: project.id,
        status: 'submitted',
        file_url: figmaUrl,
        file_name: figmaUrl,
        file_type: 'figma',
        submitted_at: new Date()
      });
    }

    // 4. Construct AI Review Prompt with authentic criteria & fetched metadata
    const evaluationCriteriaStr = JSON.stringify(project.evaluation_criteria || project.tasks || []);
    const relatedSkillsStr = JSON.stringify(project.related_skills || project.tech_stack || []);

    const userPrompt = isId
      ? `Lakukan review mendalam dan objektif untuk proyek UI/UX Design yang dikirim melalui link Figma:
Judul Proyek: ${project.title}
Target Peran Pengguna: ${user.target_role || "UI/UX Designer"}
Keahlian Terkait: ${relatedSkillsStr}
Kriteria Evaluasi Proyek: ${evaluationCriteriaStr}

INFORMASI FILE FIGMA YANG TERVERIFIKASI:
---
${figmaMetadataStr}
---

BRIEF PROYEK:
${project.brief || project.description}

Tugas Anda:
1. Evaluasi secara kritis tingkat pemenuhan kriteria di atas berdasarkan struktur dokumen Figma yang terverifikasi dan brief proyek.
2. Berikan skor (0-100), kelebihan spesifik (strengths), saran perbaikan teknis (improvements), serta status pemenuhan kriteria (objectives_met).
3. Seluruh feedback HARUS ditulis dalam BAHASA INDONESIA.

Kembalikan payload JSON yang valid dengan format persis berikut:
{
  "overall_score": <integer_0_sampai_100>,
  "strengths": ["<kelebihan_1>", "<kelebihan_2>", "<kelebihan_3>"],
  "improvements": ["<saran_perbaikan_1>", "<saran_perbaikan_2>"],
  "objectives_met": [
    { "title": "<kriteria_1>", "status": "success" },
    { "title": "<kriteria_2>", "status": "warning" }
  ],
  "ai_summary": "<ringkasan_ulasan_objektif_3_kalimat>"
}`
      : `Perform an objective, detailed UI/UX design review for the submitted Figma project link:
Project Title: ${project.title}
Target Role: ${user.target_role || "UI/UX Designer"}
Related Skills: ${relatedSkillsStr}
Evaluation Criteria: ${evaluationCriteriaStr}

VERIFIED FIGMA FILE METADATA:
---
${figmaMetadataStr}
---

PROJECT BRIEF:
${project.brief || project.description}

Evaluate strictly against the brief and criteria. Return ONLY a valid JSON object matching:
{
  "overall_score": <integer_0_to_100>,
  "strengths": ["<strength_1>", "<strength_2>"],
  "improvements": ["<improvement_1>", "<improvement_2>"],
  "objectives_met": [
    { "title": "<criteria_1>", "status": "success" },
    { "title": "<criteria_2>", "status": "warning" }
  ],
  "ai_summary": "<summary_3_sentences>"
}`;

    let reviewResult: any = null;
    const aiResponse = await callAI({
      messages: [
        {
          role: "system",
          content: `You are a Senior Lead UI/UX Product Designer performing an automated AI design review. ${
            isId ? "Output all feedback strictly in INDONESIAN language (Bahasa Indonesia)." : "Output all feedback strictly in ENGLISH language."
          }`
        },
        { role: "user", content: userPrompt }
      ],
      timeoutMs: 30000,
    });

    if (aiResponse) {
      reviewResult = this.extractJson(aiResponse);
    }

    if (!reviewResult) {
      throw new Error(
        isId
          ? "Layanan AI sedang sibuk atau tidak dapat dijangkau untuk mengevaluasi link Figma ini. Silakan coba lagi."
          : "AI Service is busy or unavailable to evaluate this Figma link. Please try again."
      );
    }

    const reviewData: UpdateSubmissionReviewDTO = {
      status: 'reviewed',
      overall_score: reviewResult.overall_score || 80,
      strengths: reviewResult.strengths || [],
      improvements: reviewResult.improvements || [],
      objectives_met: reviewResult.objectives_met || [],
      ai_summary: reviewResult.ai_summary || "Proyek Figma telah berhasil dievaluasi.",
      reviewed_at: new Date()
    };

    const reviewed = await this.miniProjectRepository.updateSubmissionReview(submission.id, reviewData);
    await this.userRepository.recomputeReadinessScore(user.id);
    return reviewed;
  }
}
