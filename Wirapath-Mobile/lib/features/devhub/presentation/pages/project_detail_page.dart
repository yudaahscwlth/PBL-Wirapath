import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/mini_project_model.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';

class ProjectDetailPage extends ConsumerStatefulWidget {
  final String projectId;
  final MiniProject? projectFromExtra;

  const ProjectDetailPage({
    super.key,
    required this.projectId,
    this.projectFromExtra,
  });

  @override
  ConsumerState<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends ConsumerState<ProjectDetailPage> {
  MiniProject? _project;
  bool _isLoading = false;
  bool _isStarting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.projectFromExtra != null) {
      _project = widget.projectFromExtra;
      // Fetch live detail for full brief & submission status
      _fetchDetail();
    } else {
      _fetchDetail();
    }
  }

  Future<void> _fetchDetail() async {
    if (_project == null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.fetchMiniProjectDetail(widget.projectId);
      if (mounted) {
        setState(() {
          final projectMap = data['project'] != null
              ? Map<String, dynamic>.from(data['project'] as Map)
              : Map<String, dynamic>.from(data);
          _project = MiniProject.fromMap(
            projectMap,
            projectMap['id']?.toString() ?? widget.projectId,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _project = _getFallbackProject(widget.projectId);
          _isLoading = false;
        });
      }
    }
  }

  MiniProject _getFallbackProject(String id) {
    final now = DateTime.now();
    if (id.startsWith('mp-ux-1')) {
      return MiniProject(
        id: 'mp-ux-1',
        title: "Figma Design System & Auto Layout Library",
        description: "Construct a scalable, responsive Figma design system incorporating Auto Layout, color design tokens, and interactive component variants.",
        brief: "Rancanglah sebuah Design System yang komprehensif dan efisien di Figma. Tugas Anda mencakup pembuatan token warna & tipografi resmi, komponen tombol & kartu yang responsif menggunakan Auto Layout, serta set varian komponen interaktif (default, hover, active, disabled).\n\nSetelah selesai, publikasikan berkas Figma Anda dan ubah aksesnya menjadi 'Anyone with the link can view', lalu kumpulkan URL file Figma tersebut untuk dievaluasi otomatis oleh sistem AI.",
        level: "Intermediate",
        duration: "6 hrs",
        tag: "Figma",
        relatedSkills: const ["Figma", "Design Systems", "Auto Layout"],
        evaluationCriteria: const [
          "Create color and typography design token styles",
          "Build flexible Auto Layout button and card components",
          "Set up interactive component state variants (hover, active)",
        ],
        sortOrder: 1,
        isActive: true,
        createdAt: now,
        submissionStatus: 'not_started',
      );
    } else if (id.startsWith('mp-ux-2')) {
      return MiniProject(
        id: 'mp-ux-2',
        title: "Mobile Usability Audit & Redesign",
        description: "Perform a Nielsen Heuristic Usability Audit on a mobile app flow, identify accessibility friction points, and deliver a high-fi interactive prototype.",
        brief: "Lakukan audit keterpakaian (Usability Audit) berdasarkan 10 Nielsen Heuristics pada alur aplikasi mobile. Identifikasi titik hambatan aksesibilitas (kontras warna WCAG 2.1 AA) dan sajikan hasil redesign dalam bentuk prototipe Figma interaktif berkualiatas tinggi.",
        level: "Intermediate",
        duration: "5 hrs",
        tag: "Usability",
        relatedSkills: const ["Figma", "Usability Testing", "WCAG"],
        evaluationCriteria: const [
          "Document usability flaws using Nielsen 10 Heuristics",
          "Audit color contrast ratios against WCAG 2.1 AA standards",
          "Build interactive high-fidelity Figma prototype",
        ],
        sortOrder: 2,
        isActive: true,
        createdAt: now,
        submissionStatus: 'not_started',
      );
    } else if (id.startsWith('mp-ux-3')) {
      return MiniProject(
        id: 'mp-ux-3',
        title: "User Research & Wireframing Flow",
        description: "Conduct user interviews, construct target User Personas and Journey Maps, and map out low-fidelity wireframe user navigation flows.",
        brief: "Lakukan riset pengguna kualitatif, sintesiskan data wawancara menjadi User Persona dan User Journey Map, kemudian buatlah alur navigasi wireframe low-fidelity yang jelas dan berfokus pada pengalaman pengguna.",
        level: "Intermediate",
        duration: "4 hrs",
        tag: "UX Research",
        relatedSkills: const ["User Research", "Wireframing", "Figma"],
        evaluationCriteria: const [
          "Synthesize qualitative interview data into Personas",
          "Map out end-to-end User Journey Map",
          "Design low-fidelity wireframe navigation flows",
        ],
        sortOrder: 3,
        isActive: true,
        createdAt: now,
        submissionStatus: 'not_started',
      );
    } else if (id.startsWith('mp-mb-1')) {
      return MiniProject(
        id: 'mp-mb-1',
        title: "Flutter Multi-Tab App with Riverpod",
        description: "Develop a multi-tab mobile application using Flutter, declarative Go Router navigation, and Riverpod reactive state management.",
        brief: "Dalam mini project ini, Anda diminta untuk membangun aplikasi Flutter mobile dengan arsitektur multi-tab yang modern. Gunakan package Go Router untuk menangani navigasi secara deklaratif, serta Riverpod (AsyncNotifier) untuk manajemen state reaktif.\n\nPastikan aplikasi mendukung navigasi antar tab dengan mulus, struktur kode bersih (Clean Architecture), serta tampilan UI yang responsif di berbagai ukuran layar. Kumpulkan link repository GitHub publik Anda setelah pengerjaan selesai.",
        level: "Intermediate",
        duration: "6 hrs",
        tag: "Flutter",
        relatedSkills: const ["Flutter", "Dart", "Riverpod", "Go Router"],
        evaluationCriteria: const [
          "Create responsive multi-tab shell navigation",
          "Implement Riverpod AsyncNotifier for state management",
          "Design responsive mobile layout screens",
        ],
        sortOrder: 1,
        isActive: true,
        createdAt: now,
        submissionStatus: 'not_started',
      );
    } else if (id.startsWith('mp-be-1')) {
      return MiniProject(
        id: 'mp-be-1',
        title: "Express REST API with JWT Auth",
        description: "Design and deploy a secure Node.js Express REST API featuring bcrypt password hashing, JWT stateless authentication, and input validation.",
        brief: "Bangun RESTful API menggunakan Node.js dan Express.js yang menyertakan sistem otentikasi stateless menggunakan JSON Web Token (JWT), hashing kata sandi dengan bcrypt, serta validasi request menggunakan Zod schema. Kumpulkan repository GitHub publik Anda untuk dievaluasi oleh sistem penguji otomatis.",
        level: "Intermediate",
        duration: "6 hrs",
        tag: "Node.js",
        relatedSkills: const ["Node.js", "Express", "JWT", "bcrypt"],
        evaluationCriteria: const [
          "Set up auth registration and login endpoints",
          "Implement JWT token validation middleware",
          "Add Zod schema request validation",
        ],
        sortOrder: 1,
        isActive: true,
        createdAt: now,
        submissionStatus: 'not_started',
      );
    }

    return MiniProject(
      id: id,
      title: "React E-Commerce Dashboard",
      description: "Build a dynamic, responsive e-commerce management dashboard using React, Tailwind CSS, and custom hooks.",
      brief: "Build a dynamic, responsive e-commerce management dashboard using React, Tailwind CSS, and custom hooks.",
      level: "Intermediate",
      duration: "6 hrs",
      tag: "React",
      relatedSkills: const ["React", "Tailwind CSS", "TypeScript"],
      evaluationCriteria: const [
        "Create responsive layout grid",
        "Implement dark mode theme switcher",
        "Build filterable product data table",
      ],
      sortOrder: 1,
      isActive: true,
      createdAt: now,
      submissionStatus: 'not_started',
    );
  }

  Future<void> _startProject() async {
    if (_project == null || _isStarting) return;
    setState(() => _isStarting = true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.startMiniProject(_project!.id);
      ref.invalidate(miniProjectsProvider);
      await _fetchDetail();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start project: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _project == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.onSurface, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _project == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.onSurface, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Failed to load project', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchDetail,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final project = _project!;
    final status = project.submissionStatus;
    final hasSubmission = status == 'submitted' || status == 'reviewed';
    final hasReview = status == 'reviewed';

    // Badge color for skill gap level (score indicates readiness, not gap)
    Color badgeColor = Colors.yellow.shade700;
    if (project.overallScore != null) {
      if (project.overallScore! >= 80) {
        badgeColor = Colors.green.shade700;
      } else if (project.overallScore! < 50) {
        badgeColor = Colors.red.shade700;
      }
    }

    return Scaffold(
      extendBody: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/devhub');
            }
          },
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${project.level} • ${project.duration}${project.tag.isNotEmpty ? ' • ${project.tag}' : ''}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
            ),
          ],
        ),
        actions: [
          if (project.overallScore != null)
            Container(
              margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '${project.overallScore!.round()}%',
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
        ],
        toolbarHeight: 80,
      ),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status banner
              if (hasSubmission) _buildStatusBanner(status),
              if (hasSubmission) const SizedBox(height: 20),

              // Brief section
              const Text(
                'Brief',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.25)),
                ),
                child: Text(
                  project.brief.isNotEmpty
                      ? project.brief
                      : project.description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),

              // Skills section
              if (project.relatedSkills.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Skills You\'ll Build',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: project.relatedSkills
                      .map((s) => Chip(
                            label: Text(s,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w600)),
                            backgroundColor:
                                AppColors.primaryBlue.withValues(alpha: 0.12),
                            side: BorderSide.none,
                          ))
                      .toList(),
                ),
              ],

              // Evaluation criteria
              if (project.evaluationCriteria.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Evaluation Criteria',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...project.evaluationCriteria.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Icon(Icons.check_circle_outline,
                                size: 16, color: Colors.blue),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(c,
                                style: TextStyle(
                                    fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
                          ),
                        ],
                      ),
                    )),
              ],

              const SizedBox(height: 30),

              // Action button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isStarting
                      ? null
                      : () {
                          if (status == 'not_started') {
                            _startProject().then((_) {
                              if (mounted) {
                                context.push(
                                  '/devhub/project/${project.id}/workspace',
                                  extra: _project ?? project,
                                );
                              }
                            });
                          } else {
                            context.push(
                              '/devhub/project/${project.id}/workspace',
                              extra: project,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: _isStarting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          hasSubmission ? 'View Submission & Results' : 'Start Project',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildStatusBanner(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case 'reviewed':
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF065F46);
        icon = Icons.check_circle_outline;
        label = 'Reviewed — see your AI feedback below';
        break;
      case 'submitted':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        icon = Icons.hourglass_empty;
        label = 'Submitted — waiting for AI review';
        break;
      default:
        bgColor = const Color(0xFFEFF6FF);
        textColor = const Color(0xFF1E40AF);
        icon = Icons.play_circle_outline;
        label = 'In Progress';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
