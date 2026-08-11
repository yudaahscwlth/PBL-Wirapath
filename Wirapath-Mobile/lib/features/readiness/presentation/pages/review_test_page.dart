import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers/user_provider.dart';

class ReviewTestPage extends ConsumerWidget {
  final Map<String, dynamic>? extraResult;

  const ReviewTestPage({super.key, this.extraResult});

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) {
      final now = DateTime.now();
      return "${_monthName(now.month)} ${now.day}, ${now.year}";
    }
    try {
      final dt = DateTime.parse(dateStr.toString());
      return "${_monthName(dt.month)} ${dt.day}, ${dt.year}";
    } catch (_) {
      return dateStr.toString();
    }
  }

  String _monthName(int month) {
    const months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return "";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (extraResult != null) {
      return _buildContent(context, ref, extraResult!);
    }

    final analyticsAsync = ref.watch(assessmentAnalyticsProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () {
            ref.invalidate(assessmentAnalyticsProvider);
            ref.invalidate(userProfileProvider);
            ref.invalidate(skillGapProvider);
            ref.invalidate(dashboardSummaryProvider);
            context.go('/readiness-center', extra: {'initialTabIndex': 2});
          },
        ),
        title: Text(
          "Assessment Result",
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text("Error loading result: $e", style: GoogleFonts.poppins()),
          ),
        ),
        data: (data) {
          if (data['has_assessment'] == false) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text("No assessment completed yet.", style: GoogleFonts.poppins()),
              ),
            );
          }
          return _buildContent(context, ref, data);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Map<String, dynamic> data) {
    final double scorePercentage = (data['score_percentage'] ?? data['overall_score'] ?? 0.0).toDouble();
    final int correctCount = (data['correct_answers'] ?? 0).toInt();
    final int totalCount = (data['total_questions'] ?? 0).toInt();
    final completedAt = data['completed_at'];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Theme-aware, status-based colors
    final Color scoreColor;
    final Color scoreBgColor;
    final String statusText;
    final Color statusColor;
    final Color statusBgColor;

    if (scorePercentage >= 75) {
      scoreColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF158031);
      scoreBgColor = isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE3);
      statusText = "Ready / Passed";
      statusColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF158031);
      statusBgColor = isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE3);
    } else if (scorePercentage >= 45) {
      scoreColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      scoreBgColor = isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
      statusText = "Developing";
      statusColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      statusBgColor = isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
    } else {
      scoreColor = isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
      scoreBgColor = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2);
      statusText = "Needs Focus";
      statusColor = isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
      statusBgColor = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2);
    }

    // Dynamic role-tailored feedback
    final String targetRole = ref.watch(userProfileProvider).value?.role ?? "Software Developer";
    final String summary;
    final List<String> strengths;
    final List<String> weaknesses;
    final String recommendation;

    final String roleLower = targetRole.toLowerCase();

    if (roleLower.contains("ui") || roleLower.contains("ux") || roleLower.contains("design")) {
      // 1. UI/UX DESIGNER
      if (scorePercentage >= 80) {
        summary = "Outstanding proficiency in UI/UX Design & Prototyping! Your design system knowledge and usability insights demonstrate industry readiness.";
        strengths = [
          "Mastery of Figma Auto-Layout & Component Variants",
          "Solid application of Jakob Nielsen Usability Heuristics",
          "Strong WCAG accessibility contrast compliance"
        ];
        weaknesses = [
          "Complex interactive micro-animation prototyping",
          "Design system token synchronization with dev codebases"
        ];
        recommendation = "Challenge yourself with interactive prototype projects in the Dev Hub to refine your UI/UX portfolio.";
      } else if (scorePercentage >= 50) {
        summary = "Good foundational knowledge in UI/UX Design, but user research frameworks and design system tokens require practical refinement.";
        strengths = [
          "Solid grasp of Figma layout structure & visual hierarchy",
          "Good awareness of basic usability principles"
        ];
        weaknesses = [
          "Complex user journey mapping and wireframing edge cases",
          "Design system token integration and handoff documentation"
        ];
        recommendation = "Complete the Design System & Prototyping modules in Dev Hub to boost your readiness score above 80%.";
      } else {
        summary = "Foundational concepts in UI/UX Design require structured learning. Focused practice in Figma will accelerate your progress.";
        strengths = [
          "Basic visual design awareness",
          "Genuine interest in user-centered design"
        ];
        weaknesses = [
          "Figma component properties & layout constraints",
          "Heuristic evaluation & WCAG accessibility guidelines"
        ];
        recommendation = "Review fundamental Figma tutorials and attempt wireframing tasks in Dev Hub.";
      }
    } else if (roleLower.contains("mobile")) {
      // 2. MOBILE DEVELOPER
      if (scorePercentage >= 80) {
        summary = "Outstanding proficiency in Mobile Development! Your Flutter & cross-platform knowledge demonstrates strong app production readiness.";
        strengths = [
          "Mastery of Flutter widget lifecycle & Dart async programming",
          "Effective reactive state management (Riverpod/BLoC)",
          "Proper native device API integration & offline caching"
        ];
        weaknesses = [
          "Complex custom canvas rendering (CustomPainter)",
          "Deep native iOS/Android platform channel bridge edge cases"
        ];
        recommendation = "Build advanced cross-platform apps in Dev Hub to publish to your mobile portfolio.";
      } else if (scorePercentage >= 50) {
        summary = "Good foundational knowledge for Mobile Development, but state management listeners and local storage sync require refinement.";
        strengths = [
          "Understanding of core Flutter widget trees & Dart syntax",
          "Consistent execution on responsive mobile UI layouts"
        ];
        weaknesses = [
          "Complex Riverpod/BLoC state listeners & declarative routing",
          "Local SQLite/Hive database offline sync edge cases"
        ];
        recommendation = "Complete targeted Mobile State & Storage modules in Dev Hub to reach 80%+ readiness.";
      } else {
        summary = "Foundational concepts in Mobile Development require structured practice. Focused learning in Flutter will build your confidence.";
        strengths = [
          "Basic Flutter layout awareness",
          "Eagerness to build cross-platform mobile apps"
        ];
        weaknesses = [
          "Flutter StatefulWidget lifecycle & constructor constraints",
          "Basic reactive state management patterns"
        ];
        recommendation = "Start with foundational Flutter & Dart exercises in Dev Hub.";
      }
    } else if (roleLower.contains("frontend")) {
      // 3. FRONTEND DEVELOPER
      if (scorePercentage >= 80) {
        summary = "Outstanding proficiency in Frontend Development! Your React/Vue architecture, CSS layout, and DOM performance skills are industry ready.";
        strengths = [
          "Mastery of React hooks, memoization & component state",
          "Expert 2D responsive layout design (CSS Grid & Flexbox)",
          "Strong web performance optimization & CLS reduction"
        ];
        weaknesses = [
          "Micro-frontend bundle splitting nuances",
          "Complex client-side caching & Service Worker edge cases"
        ];
        recommendation = "Build complex frontend web applications in Dev Hub to showcase your technical stack.";
      } else if (scorePercentage >= 50) {
        summary = "Good foundational knowledge in Frontend Development, but DOM rendering performance and state memoization require practical application.";
        strengths = [
          "Solid grasp of modern JavaScript/TypeScript syntax",
          "Consistent execution on responsive layout structures"
        ];
        weaknesses = [
          "Cumulative Layout Shift (CLS) & browser repaint bottlenecks",
          "Complex state re-render prevention strategies"
        ];
        recommendation = "Complete targeted Web Performance modules in Dev Hub to boost your score above 80%.";
      } else {
        summary = "Foundational concepts in Frontend Web Development require structured learning. Focused practice in HTML/CSS/JS will build your core.";
        strengths = ["Basic web layout awareness", "Strong drive for frontend development"];
        weaknesses = ["Semantic HTML structure & accessibility principles", "CSS Grid & Flexbox alignment rules"];
        recommendation = "Review core web fundamentals and practice layout exercises in Dev Hub.";
      }
    } else if (roleLower.contains("backend")) {
      // 4. BACKEND DEVELOPER
      if (scorePercentage >= 80) {
        summary = "Outstanding proficiency in Backend Development! Your REST API architecture, database indexing, and security practices are production ready.";
        strengths = [
          "Mastery of Node.js Express middleware routing & async control",
          "Solid database indexing & B-Tree range query optimization",
          "Robust API security, bcrypt hashing & JWT stateless auth"
        ];
        weaknesses = [
          "Distributed transaction isolation edge cases",
          "High-concurrency Redis caching eviction policies"
        ];
        recommendation = "Build scalable API services and database architecture in Dev Hub to enrich your portfolio.";
      } else if (scorePercentage >= 50) {
        summary = "Good foundational knowledge in Backend Development, but database EXPLAIN query profiling and rate limiting require deeper practice.";
        strengths = [
          "Understanding of HTTP status codes & REST route conventions",
          "Solid implementation of JWT authentication routines"
        ];
        weaknesses = [
          "Database transaction isolation levels & full table scan risks",
          "Rate limiting & CORS preflight header security"
        ];
        recommendation = "Complete targeted Database & API Security modules in Dev Hub to reach 80%+ readiness.";
      } else {
        summary = "Foundational concepts in Backend Development require structured study. Focused learning on server routing & SQL will accelerate your growth.";
        strengths = ["Basic server routing awareness", "Eagerness to design backend systems"];
        weaknesses = ["HTTP request handling & status code standards", "Relational database schema modeling"];
        recommendation = "Start with basic Express API tutorials and database queries in Dev Hub.";
      }
    } else if (roleLower.contains("fullstack")) {
      // 5. FULLSTACK DEVELOPER
      if (scorePercentage >= 80) {
        summary = "Outstanding fullstack capability! Your integration across SSR web frameworks, API gateways, and ORM database schemas is highly proficient.";
        strengths = [
          "Seamless Next.js SSR pre-rendering & client state architecture",
          "Robust API authorization headers & microservice queues",
          "Clean ORM migrations & relational integrity enforcement"
        ];
        weaknesses = [
          "Fullstack N+1 database query waterfall edge cases",
          "Zero-downtime deployment & reverse proxy configuration"
        ];
        recommendation = "Build fullstack end-to-end web platforms in Dev Hub to highlight your versatile capabilities.";
      } else if (scorePercentage >= 50) {
        summary = "Good foundational knowledge across the fullstack, but ORM N+1 query optimization and token refresh cycles need refinement.";
        strengths = [
          "Solid understanding of frontend-backend contract integration",
          "Consistent database ORM schema modeling"
        ];
        weaknesses = [
          "Asynchronous job worker queues & Redis caching",
          "Automatic client-side token refresh implementation"
        ];
        recommendation = "Complete Fullstack Practice modules in Dev Hub to elevate your readiness index.";
      } else {
        summary = "Foundational concepts across fullstack development require structured learning. Start by building core web and server confidence.";
        strengths = ["Broad interest in end-to-end web technology", "Strong learning motivation"];
        weaknesses = ["Client-server state synchronization", "Database ORM setup & API routing"];
        recommendation = "Practice basic fullstack starter projects in Dev Hub.";
      }
    } else if (roleLower.contains("data") || roleLower.contains("scientist") || roleLower.contains("ai")) {
      // 6. DATA SCIENTIST
      if (scorePercentage >= 80) {
        summary = "Outstanding proficiency in Data Science & Machine Learning! Your data preprocessing, model evaluation, and ETL pipelines are production ready.";
        strengths = [
          "Mastery of Pandas DataFrame operations & vectorization",
          "Solid ML model evaluation (F1-Score, ROC-AUC, K-Fold CV)",
          "Effective data engineering pipelines & SQL window functions"
        ];
        weaknesses = [
          "Hyperparameter tuning optimization bottlenecks",
          "Model tracking & artifact versioning in production"
        ];
        recommendation = "Build machine learning pipelines in Dev Hub to showcase your data science expertise.";
      } else if (scorePercentage >= 50) {
        summary = "Good foundational knowledge in Data Science, but machine learning overfitting controls and feature engineering require practice.";
        strengths = [
          "Good understanding of Python data stack & NumPy arrays",
          "Clear execution on categorical encoding & data cleaning"
        ];
        weaknesses = [
          "Handling class imbalance & evaluating non-accuracy metrics",
          "Advanced SQL window functions & automated ETL"
        ];
        recommendation = "Complete ML Model Evaluation & Data Engineering modules in Dev Hub to score above 80%.";
      } else {
        summary = "Foundational concepts in Data Science require structured practice. Focused learning in Python & SQL will build your analytical skills.";
        strengths = ["Basic data awareness", "Strong analytical curiosity"];
        weaknesses = ["Python Pandas DataFrame manipulation", "Machine learning algorithm fundamentals"];
        recommendation = "Practice Python data analysis exercises in Dev Hub.";
      }
    } else {
      // General Fallback
      if (scorePercentage >= 80) {
        summary = "Outstanding proficiency in $targetRole competencies! Your technical knowledge demonstrates strong readiness for professional roles.";
        strengths = [
          "Mastery of core $targetRole concepts & architecture",
          "High accuracy in practical technical problem-solving",
          "Solid adherence to clean code & industry standards"
        ];
        weaknesses = [
          "Advanced system architecture optimization edge cases",
          "Deep runtime performance profiling nuances"
        ];
        recommendation = "Challenge yourself with complex mini-projects in the Dev Hub to refine your portfolio.";
      } else if (scorePercentage >= 50) {
        summary = "Good foundational knowledge for $targetRole, but key technical concepts require further practical application and refinement.";
        strengths = [
          "Understanding of core $targetRole fundamentals & logic",
          "Consistent execution on baseline evaluation tasks"
        ];
        weaknesses = [
          "Complex scenario logic and edge-case validation",
          "Deep framework & tooling specification nuances"
        ];
        recommendation = "Complete targeted practice modules in Dev Hub to boost your readiness score above 80%.";
      } else {
        summary = "Fundamental concepts for $targetRole require structured study. Focused learning will significantly accelerate your progress.";
        strengths = [
          "Basic conceptual awareness",
          "Clear potential for growth in $targetRole"
        ];
        weaknesses = [
          "Foundational technical terminology & core principles",
          "Practical task implementation & validation rules"
        ];
        recommendation = "Review foundational study materials and attempt mini-projects in Dev Hub to build hands-on skills.";
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: extraResult != null
          ? AppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.onSurface, size: 20),
                onPressed: () => context.go('/readiness-center', extra: {'initialTabIndex': 1}),
              ),
              title: Text(
                "Assessment Complete",
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            )
          : null, // Scaffolding has its own appbar in GoRouter nested views if no extraResult
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Initial Assessment Results",
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),
            
            // Score Display Row
            Row(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: scoreBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "${scorePercentage.round()}",
                            style: GoogleFonts.poppins(
                              color: scoreColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 36,
                            ),
                          ),
                          TextSpan(
                            text: "%",
                            style: GoogleFonts.poppins(
                              color: scoreColor.withValues(alpha: 0.7),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Test Graded",
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        "Submitted ${_formatDate(completedAt)}",
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: GoogleFonts.poppins(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            Text(
              "Score Breakdown: $correctCount out of $totalCount questions answered correctly.",
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),

            // Per-question answer review (only available right after submitting).
            if (data['results'] is List && (data['results'] as List).isNotEmpty) ...[
              const SizedBox(height: 32),
              _buildSectionHeader(
                context: context,
                icon: Icons.fact_check_rounded,
                title: "Review Your Answers",
              ),
              const SizedBox(height: 12),
              ...List<Widget>.from(
                (data['results'] as List).asMap().entries.map(
                      (e) => _buildAnswerReviewCard(
                        context,
                        isDark,
                        e.key,
                        Map<String, dynamic>.from(e.value as Map),
                      ),
                    ),
              ),
            ],

            const SizedBox(height: 32),

            // Tailored Overview
            _buildSectionHeader(
              context: context,
              icon: Icons.star_rounded,
              title: "AI Review Summary",
            ),
            const SizedBox(height: 12),
            Text(
              summary,
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Strengths and Weaknesses side by side / stacked
            Column(
              children: [
                // Strengths
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF14532D).withValues(alpha: 0.3) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF065F46).withValues(alpha: 0.5) : const Color(0xFFA7F3D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF059669), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "STRENGTHS",
                            style: GoogleFonts.poppins(
                              color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF047857),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...strengths.map((str) => Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("• ", style: TextStyle(color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF059669))),
                                Expanded(
                                  child: Text(
                                    str,
                                    style: GoogleFonts.poppins(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Weaknesses
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.2) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF991B1B).withValues(alpha: 0.5) : const Color(0xFFFCA5A5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "WEAKNESSES",
                            style: GoogleFonts.poppins(
                              color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...weaknesses.map((weak) => Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("• ", style: TextStyle(color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626))),
                                Expanded(
                                  child: Text(
                                    weak,
                                    style: GoogleFonts.poppins(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Recommendation
            _buildSectionHeader(
              context: context,
              icon: Icons.track_changes_rounded,
              title: "Recommendation",
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF1E40AF).withValues(alpha: 0.5) : const Color(0xFFBFDBFE)),
              ),
              child: Text(
                recommendation,
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {
                        // Invalidate first to make sure we fetch fresh questions
                        ref.invalidate(assessmentQuestionsProvider);
                        context.go('/readiness-center/initial-test');
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      child: Text(
                        "Retake Test",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.invalidate(assessmentAnalyticsProvider);
                        ref.invalidate(userProfileProvider);
                        ref.invalidate(skillGapProvider);
                        ref.invalidate(dashboardSummaryProvider);
                        context.go('/readiness-center', extra: {'initialTabIndex': 2});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF066EFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Close",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  /// Resolve a stored answer id (e.g. "A", "yes") to its readable label.
  String _labelFor(Map<String, dynamic> review, String? value) {
    if (value == null || value.isEmpty) return "—";
    final type = (review['question_type'] ?? '').toString();
    if (type == 'yes_no') {
      if (value.toLowerCase() == 'yes') return 'Yes';
      if (value.toLowerCase() == 'no') return 'No';
    }
    final options = (review['options'] as List?) ?? const [];
    for (final o in options) {
      if (o is Map && (o['id']?.toString() == value)) {
        return (o['text'] ?? value).toString();
      }
    }
    return value;
  }

  Widget _buildAnswerReviewCard(
      BuildContext context, bool isDark, int index, Map<String, dynamic> review) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isCorrect = review['is_correct'] == true;
    final userLabel = _labelFor(review, review['user_answer']?.toString());
    final correctLabel = _labelFor(review, review['correct_answer']?.toString());
    final category = (review['category_name'] ?? '').toString();
    final explanation = (review['explanation'] ?? '').toString();

    final Color accent = isCorrect
        ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF059669))
        : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626));
    final Color bg = isCorrect
        ? (isDark ? const Color(0xFF14532D).withValues(alpha: 0.25) : const Color(0xFFECFDF5))
        : (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.2) : const Color(0xFFFEF2F2));
    final Color border = isCorrect
        ? (isDark ? const Color(0xFF065F46).withValues(alpha: 0.5) : const Color(0xFFA7F3D0))
        : (isDark ? const Color(0xFF991B1B).withValues(alpha: 0.5) : const Color(0xFFFCA5A5));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(isCorrect ? Icons.check_circle : Icons.cancel,
                  color: accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (category.isNotEmpty)
                      Text(
                        category.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: onSurface.withValues(alpha: 0.45),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    Text(
                      "${index + 1}. ${review['question_text'] ?? ''}",
                      style: GoogleFonts.poppins(
                        color: onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(fontSize: 12, color: onSurface.withValues(alpha: 0.6)),
              children: [
                const TextSpan(text: "Your answer: "),
                TextSpan(
                  text: userLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 2),
            RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(fontSize: 12, color: onSurface.withValues(alpha: 0.6)),
                children: [
                  const TextSpan(text: "Correct answer: "),
                  TextSpan(
                    text: correctLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              explanation,
              style: GoogleFonts.poppins(
                color: onSurface.withValues(alpha: 0.6),
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required BuildContext context, required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF0844C5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
