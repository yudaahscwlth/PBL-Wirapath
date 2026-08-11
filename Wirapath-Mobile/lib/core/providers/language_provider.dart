import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported UI languages. Mirrors the website's i18n (lib/i18n.tsx):
/// English (US), Bahasa Indonesia, English (UK) and Japanese. English variants
/// share the same dictionary, exactly like the web reference.
enum AppLanguage { enUs, id, enUk, jp }

extension AppLanguageX on AppLanguage {
  /// Stable identifier persisted to storage. Matches the web `LanguageId`
  /// values so both clients speak the same language codes.
  String get code {
    switch (this) {
      case AppLanguage.enUs:
        return 'en-us';
      case AppLanguage.id:
        return 'id';
      case AppLanguage.enUk:
        return 'en-uk';
      case AppLanguage.jp:
        return 'jp';
    }
  }

  /// Human-readable label shown in the picker (kept in English to match web).
  String get label {
    switch (this) {
      case AppLanguage.enUs:
        return 'English (US)';
      case AppLanguage.id:
        return 'Bahasa Indonesia';
      case AppLanguage.enUk:
        return 'English (UK)';
      case AppLanguage.jp:
        return 'Japanese';
    }
  }

  static AppLanguage fromCode(String? code) {
    switch (code) {
      case 'id':
        return AppLanguage.id;
      case 'en-uk':
        return AppLanguage.enUk;
      case 'jp':
        return AppLanguage.jp;
      case 'en-us':
      default:
        return AppLanguage.enUs;
    }
  }
}

// Translation dictionaries. Keys mirror lib/i18n.tsx on the website so the two
// codebases stay in sync. Missing keys fall back to the English value, then the
// raw key, so untranslated strings still render gracefully.
const Map<String, String> _en = {
  // ── Appearance / settings ──
  'settings.appearance': 'Language & Appearance',
  'appearance.title': 'Language & Appearance',
  'appearance.subtitle': 'Customize app theme and language',
  'appearance.language': 'Language',
  'appearance.theme': 'Theme',
  'theme.light': 'Light',
  'theme.dark': 'Dark',
  'theme.system': 'System',
  // ── Bottom nav ──
  'nav.home': 'Home',
  'nav.readiness': 'Readiness',
  'nav.devhub': 'Dev Hub',
  'nav.simulation': 'Simulation',
  'nav.profile': 'Profile',
  // ── Search ──
  'search.hint': 'Search features...',
  'search.empty': 'No features found',
  // ── Common ──
  'common.view_all': 'View All',
  'common.loading': 'Loading...',
  'common.analyzing': 'Analyzing...',
  'common.progress': 'Progress',
  'common.continue': 'Continue',
  'common.save': 'Save',
  'common.save_changes': 'Save Changes',
  'common.cancel': 'Cancel',
  'common.back': 'Back',
  'common.skip_for_now': 'Skip for now',
  'common.user': 'User',
  'common.retry': 'Retry',
  // ── Skill statuses ──
  'status.weak': 'Weak',
  'status.enough': 'Enough',
  'status.strong': 'Strong',
  // ── Full feature names ──
  'feature.readiness': 'Readiness Center',
  'feature.devhub': 'Development Hub',
  'feature.simulation': 'Career Simulation',
  'feature.jobdesk': 'Jobdesk Analyzer',
  // ── Home ──
  'home.welcome_back': 'Welcome back!',
  'home.skills_attention': 'Skills That Need Attention',
  'home.great_job': 'Great job!',
  'home.skills_all_strong':
      'All your skills are strong and meet the required role threshold.',
  'home.achievement_progress': 'Your Achievement Progress',
  'home.quick_actions': 'Quick Actions',
  'home.take_initial': 'Take Initial Assessment',
  'home.boost_accuracy': 'Boost your readiness accuracy',
  'home.upcoming_tasks': 'Upcoming Tasks',
  'home.growth_progress': 'Growth Progress',
  'home.this_month': 'THIS MONTH',
  'home.skills_mapped': 'Skills Mapped',
  'home.projects_done': 'Projects Done',
  'home.simulations': 'Simulations',
  'home.continue_working': 'Continue Working',
  'home.nothing_progress':
      'Nothing in progress yet.\nStart a project or simulation to see it here.',
  'home.recently_visited': 'Recently visited',
  'home.data_footer':
      'Real-time market insights powered by AI analytics',
  'home.readiness_index': 'Your Readiness Index today',
  'home.growing': 'Growing',
  'home.predicted_role': 'Predicted role:',
  'home.up_last_week': '↑ Up from last week',
  'home.day_streak': 'Day streak today',
  'home.career_seeker': 'Career Seeker',
  'home.failed_skills': 'Failed to load skills',
  'home.error_profile': 'Error loading profile',
  'common.recent': 'Recent',
  // ── Profile ──
  'profile.title': 'Profile',
  'profile.tab_my': 'My Profile',
  'profile.tab_settings': 'Settings',
  'profile.role_default': 'Frontend Developer',
  'profile.stat_readiness': 'Readiness\nIndex',
  'profile.stat_gaps': 'Skills That Need\nImproved',
  'profile.stat_projects': 'Mini\nProject',
  'profile.stat_tests': 'Skill Test\nAttempts',
  'profile.validated_competitions': 'Validated Competitions',
  'profile.no_competitions': 'No Verified Competitions Yet',
  'profile.no_competitions_desc':
      'Complete a mini project in Dev Hub or take an assessment in the Readiness Center to validate your skill badges.',
  'profile.skill_details': 'Your Skill Details',
  'profile.documents': 'Documents',
  'profile.no_documents': 'No documents uploaded yet',
  'profile.transcript': 'Transcript',
  'profile.upload_cv': 'Upload CV',
  'profile.replace_cv': 'Replace CV',
  'profile.upload_transcript': 'Upload Transcript',
  'profile.replace_transcript': 'Replace Transcript',
  'profile.cannot_read_file': 'Could not read the selected file',
  'profile.upload_failed': 'Upload failed',
  'profile.cannot_open_doc': 'Could not open document',
  'profile.doc_uploaded_suffix': 'uploaded successfully',
  'profile.account_settings': 'Account Settings',
  'profile.preferences': 'Preferences',
  'profile.integrations_support': 'Integrations & Support',
  'profile.personal_info': 'Personal Information',
  'profile.password_security': 'Password & Security',
  'profile.notifications': 'Notifications',
  'profile.integrations': 'Integrations',
  'profile.help_support': 'Help & Support',
  'profile.logout': 'Log Out',
  // ── DevHub ──
  'devhub.subtitle': 'Level up your skills and work readiness',
  'devhub.mini_project': 'Mini Project',
  'devhub.code_review': 'Code Review',
  'devhub.skill_map': 'Your Skill Map',
  'devhub.projects_for_you': 'Mini Projects for You',
  'devhub.no_projects': 'No projects available yet.',
  'devhub.not_submitted': 'Not submitted yet',
  'devhub.code_review_title': 'AI Code Review',
  'devhub.code_review_desc': 'Submit code from your mini project and get specific feedback just like a senior developer\'s code review.',
  'devhub.code_review_item1': 'Clean Code & Best Practices',
  'devhub.code_review_item2': 'Error Handling',
  'devhub.code_review_item3': 'Performance Optimization',
  'devhub.code_review_item4': 'Specific Improvement Suggestions',
  'devhub.code_review_submit': 'Submit Code for Review',
  // ── Career Simulation ──
  'simulation.subtitle': 'Practice mock interviews and negotiations',
  'simulation.history': 'Conversation History',
  'simulation.end_button': 'End',
  'simulation.options_title': 'Choose a Simulation Mode',
  'simulation.options_desc': 'Interactive scenarios with real Indonesian companies and roles',
  'simulation.failed_eval': 'Could not generate your evaluation. Please try again.',
  'simulation.try_another': 'Try Another Simulation',
  'simulation.interesting_questions': 'Interesting Questions',
  'simulation.no_history': 'No simulation history found. Start a new session above!',
  'simulation.mentor_intro': 'Hello! I\'m your AI Mentor. Choose the simulation you\'d like to practice today',
  'simulation.salary_negotiation': 'Salary Negotiation',
  'simulation.english_interview': 'English Interview',
  'simulation.select_scenario': 'Select a company scenario for Career Simulation.',
  'simulation.select_salary': 'Select a company to start the Salary Negotiation:',
  'simulation.jobdesk_intro': 'I found several job listings matching your profile from LinkedIn, Jobstreet, and Glints. Tap "Analyze Job" to see a detailed skill match analysis.',
  'simulation.enter_custom_job': 'Enter custom job (e.g. Flutter Developer)',
  'simulation.analyze_btn': 'Analyze',
  'simulation.initializing_chat': 'Initializing chat mentorship session...',
  'simulation.ai_responding': 'AI Mentor is responding...',
  'simulation.market_skill_demand': 'Market Skill Demand',
  'simulation.confidence_threshold': 'Confidence threshold: ',
  'simulation.matched': 'Matched',
  'simulation.gap': 'Gap',
  'simulation.analyzing_job_reqs': 'Analyzing Job Requirements...',
  'simulation.fetching_db': 'Fetching market skills database for job predictions...',
  'simulation.lulus': 'Passed',
  'simulation.belum_lulus': 'Not Passed',
  'simulation.negotiation_completed': 'Negotiation Completed',
  'simulation.salary_performance': 'Salary Negotiation Performance',
  'simulation.interview_report': 'Interview Simulation Report',
  'simulation.evaluation_desc': 'AI-generated evaluation of your responses.',
  'simulation.end_negotiation': 'End negotiation',
  'simulation.end_interview': 'End interview',
  // ── Jobdesk Analyzer ──
  'jobdesk.subtitle': 'Paste a job description to analyze how it matches your profile.',
  'jobdesk.hint': 'Paste a job description here...',
  'jobdesk.button': 'Analyze Job Description',
  'jobdesk.error_empty': 'Please paste a job description first.',
  'jobdesk.error_invalid': 'Invalid job title or description. Please try with a valid professional role.',
  'jobdesk.match_score': 'Profile match',
  'jobdesk.summary': 'Summary',
  'jobdesk.matching_skills': 'Matching Skills',
  'jobdesk.missing_skills': 'Missing Skills',
  'jobdesk.recommendations': 'Recommendations',
  // ── Readiness Center ──
  'readiness.subtitle': 'Analyze & measure your work readiness',
  'readiness.overview': 'Overview',
  'readiness.initial_test': 'Initial Test',
  'readiness.skill_map': 'Skill Map',
  'readiness.skill_gap': 'Skill Gap',
  'readiness.cv_analysis': 'CV Analysis',
  'readiness.transcript_analysis': 'Academic Transcript Analysis',
  'readiness.start_assessment': 'Start Assessment',
  'readiness.retake_test': 'Retake Test',
  'readiness.view_details': 'View Details',
  'readiness.skills_mapped': 'Skills Mapped',
  'readiness.critical_gaps': 'Critical Gaps',
  'readiness.strengths': 'Strengths',
  'readiness.cv_upload_success': 'CV uploaded and analyzed successfully.',
  'readiness.transcript_upload_success': 'Academic transcript uploaded successfully.',
  'readiness.upload_failed': 'Upload failed. Please try again.',
  'readiness.overall_readiness': 'Overall Readiness',
  'readiness.cv_name_empty': 'No CV uploaded',
  'readiness.cv_desc_present': 'Your CV has been uploaded and analyzed against your target role.',
  'readiness.cv_desc_empty': 'You haven\'t uploaded a CV yet. Upload one to get a personalized analysis of your skills and gaps.',
  'readiness.cv_action_upload': 'Upload CV',
  'readiness.cv_action_reupload': 'Re-Upload CV',
  'readiness.transcript_name_empty': 'No transcript uploaded',
  'readiness.transcript_desc_present': 'Your academic transcript has been uploaded and analyzed.',
  'readiness.transcript_desc_empty': 'You haven\'t uploaded an academic transcript yet. Upload one to include your academic performance in your readiness score.',
  'readiness.transcript_action_upload': 'Upload Academic Transcript',
  'readiness.transcript_action_reupload': 'Re-Upload Academic Transcript',
  'readiness.banner_title': 'Check Your CV Now',
  'readiness.banner_desc': 'Curious how your CV performs in front of recruiters? Upload it and let AI give you instant insights and improvement tips.',
  'readiness.uploading': 'Uploading...',
  'readiness.sign_in_required': 'Please sign in again to upload documents.',
  'readiness.initial_test_title': 'Initial Skill Assessment',
  'readiness.initial_test_desc': 'Complement your CV and GitHub analysis with a direct knowledge assessment. This test evaluates your skills across your role-mapped categories to give an accurate readiness score.',
  'readiness.stats_questions': 'Questions',
  'readiness.stats_questions_val': 'Dynamic pool',
  'readiness.stats_duration': 'Duration',
  'readiness.stats_duration_val': '~10 Mins',
  'readiness.stats_targeted': 'Targeted',
  'readiness.stats_targeted_val': 'Role-aligned',
  'readiness.helps_title': 'How this helps your readiness score',
  'readiness.helps_desc': 'Taking this assessment adds a third evaluation dimension to your CV and GitHub activity, making your Skill Map and Skill Gap analysis significantly more accurate.',
  'readiness.score': 'Score',
  'readiness.result_excellent': 'Excellent Work!',
  'readiness.result_good': 'Keep Practicing!',
  'readiness.result_focus': 'Focus & Improve!',
  'readiness.completed_on': 'Completed on ',
  'readiness.recently': 'recently',
  'readiness.status_ready': 'Ready / Passed',
  'readiness.status_developing': 'Developing',
  'readiness.status_needs_focus': 'Needs Focus',
  'readiness.skill_map_title': 'Your Skill Map',
  'readiness.skill_details_title': 'Your Skill Details',
  'readiness.skill_level': 'Level: ',
  'readiness.gap_to_learn': 'Needs to Be Learned',
  'readiness.gap_to_improve': 'Needs Improvement',
  'readiness.gap_already_strong': 'Already Strong',
  'readiness.desc_to_learn': 'High priority gap • Recruiter demand: critical',
  'readiness.desc_to_improve': 'Medium priority gap • Recruiter demand: moderate',
  'readiness.desc_already_strong': 'Competency high • Recruiter demand: satisfied',
  'readiness.market_demand': 'Top Industry Skills',
  'devhub.skill_map_empty_title': 'Skill Map Not Available Yet',
  'devhub.skill_map_empty_desc': 'Complete the Initial Test first to unlock your skill map.',
  'devhub.start_initial_test': 'Start Initial Test',
};

const Map<String, String> _id = {
  // ── Appearance / settings ──
  'settings.appearance': 'Bahasa & Tampilan',
  'appearance.title': 'Bahasa & Tampilan',
  'appearance.subtitle': 'Sesuaikan tema dan bahasa aplikasi',
  'appearance.language': 'Bahasa',
  'appearance.theme': 'Tema',
  'theme.light': 'Terang',
  'theme.dark': 'Gelap',
  'theme.system': 'Sistem',
  // ── Bottom nav ──
  'nav.home': 'Beranda',
  'nav.readiness': 'Kesiapan',
  'nav.devhub': 'Dev Hub',
  'nav.simulation': 'Simulasi',
  'nav.profile': 'Profil',
  // ── Search ──
  'search.hint': 'Cari fitur...',
  'search.empty': 'Fitur tidak ditemukan',
  // ── Common ──
  'common.view_all': 'Lihat Semua',
  'common.loading': 'Memuat...',
  'common.analyzing': 'Menganalisis...',
  'common.progress': 'Progres',
  'common.continue': 'Lanjut',
  'common.save': 'Simpan',
  'common.save_changes': 'Simpan Perubahan',
  'common.cancel': 'Batal',
  'common.back': 'Kembali',
  'common.skip_for_now': 'Lewati dulu',
  'common.user': 'Pengguna',
  'common.retry': 'Coba lagi',
  // ── Skill statuses ──
  'status.weak': 'Lemah',
  'status.enough': 'Cukup',
  'status.strong': 'Kuat',
  // ── Full feature names ──
  'feature.readiness': 'Pusat Kesiapan',
  'feature.devhub': 'Pusat Pengembangan',
  'feature.simulation': 'Simulasi Karier',
  'feature.jobdesk': 'Penganalisis Lowongan',
  // ── Home ──
  'home.welcome_back': 'Selamat datang kembali!',
  'home.skills_attention': 'Keterampilan yang Perlu Diperhatikan',
  'home.great_job': 'Kerja bagus!',
  'home.skills_all_strong':
      'Semua keterampilan Anda kuat dan memenuhi ambang batas peran yang dibutuhkan.',
  'home.achievement_progress': 'Progres Pencapaian Anda',
  'home.quick_actions': 'Aksi Cepat',
  'home.take_initial': 'Ikuti Asesmen Awal',
  'home.boost_accuracy': 'Tingkatkan akurasi kesiapan Anda',
  'home.upcoming_tasks': 'Tugas Mendatang',
  'home.growth_progress': 'Progres Pertumbuhan',
  'home.this_month': 'BULAN INI',
  'home.skills_mapped': 'Keterampilan Dipetakan',
  'home.projects_done': 'Proyek Selesai',
  'home.simulations': 'Simulasi',
  'home.continue_working': 'Lanjutkan Mengerjakan',
  'home.nothing_progress':
      'Belum ada yang sedang berjalan.\nMulai proyek atau simulasi untuk melihatnya di sini.',
  'home.recently_visited': 'Baru saja dikunjungi',
  'home.data_footer':
      'Analisis data kesiapan kerja berbasis kecerdasan buatan',
  'home.readiness_index': 'Indeks Kesiapan Anda hari ini',
  'home.growing': 'Bertumbuh',
  'home.predicted_role': 'Prediksi peran:',
  'home.up_last_week': '↑ Naik dari minggu lalu',
  'home.day_streak': 'Hari beruntun hari ini',
  'home.career_seeker': 'Pencari Karier',
  'home.failed_skills': 'Gagal memuat keterampilan',
  'home.error_profile': 'Gagal memuat profil',
  'common.recent': 'Baru-baru ini',
  // ── Profile ──
  'profile.title': 'Profil',
  'profile.tab_my': 'Profil Saya',
  'profile.tab_settings': 'Pengaturan',
  'profile.role_default': 'Frontend Developer',
  'profile.stat_readiness': 'Indeks\nKesiapan',
  'profile.stat_gaps': 'Keterampilan yang\nPerlu Ditingkatkan',
  'profile.stat_projects': 'Mini\nProyek',
  'profile.stat_tests': 'Percobaan\nTes Skill',
  'profile.validated_competitions': 'Kompetensi Tervalidasi',
  'profile.no_competitions': 'Belum Ada Kompetisi Terverifikasi',
  'profile.no_competitions_desc':
      'Selesaikan mini project di Dev Hub atau ikuti asesmen di Readiness Center untuk mendapatkan lencana kompetensi terverifikasi.',
  'profile.skill_details': 'Detail Keterampilan Anda',
  'profile.documents': 'Dokumen',
  'profile.no_documents': 'Belum ada dokumen diunggah',
  'profile.transcript': 'Transkrip',
  'profile.upload_cv': 'Unggah CV',
  'profile.replace_cv': 'Ganti CV',
  'profile.upload_transcript': 'Unggah Transkrip',
  'profile.replace_transcript': 'Ganti Transkrip',
  'profile.cannot_read_file': 'Tidak dapat membaca file yang dipilih',
  'profile.upload_failed': 'Gagal mengunggah',
  'profile.cannot_open_doc': 'Tidak dapat membuka dokumen',
  'profile.doc_uploaded_suffix': 'berhasil diunggah',
  'profile.account_settings': 'Pengaturan Akun',
  'profile.preferences': 'Preferensi',
  'profile.integrations_support': 'Integrasi & Dukungan',
  'profile.personal_info': 'Informasi Pribadi',
  'profile.password_security': 'Kata Sandi & Keamanan',
  'profile.notifications': 'Notifikasi',
  'profile.integrations': 'Integrasi',
  'profile.help_support': 'Bantuan & Dukungan',
  'profile.logout': 'Keluar',
  // ── DevHub ──
  'devhub.subtitle': 'Tingkatkan keterampilan dan kesiapan kerja Anda',
  'devhub.mini_project': 'Mini Proyek',
  'devhub.code_review': 'Tinjauan Kode',
  'devhub.skill_map': 'Peta Keterampilan Anda',
  'devhub.projects_for_you': 'Mini Proyek untuk Anda',
  'devhub.no_projects': 'Belum ada proyek yang tersedia.',
  'devhub.not_submitted': 'Belum diajukan',
  'devhub.code_review_title': 'Tinjauan Kode AI',
  'devhub.code_review_desc': 'Kirim kode dari proyek mini Anda dan dapatkan umpan balik khusus seperti tinjauan kode developer senior.',
  'devhub.code_review_item1': 'Kode Bersih & Praktik Terbaik',
  'devhub.code_review_item2': 'Penanganan Kesalahan',
  'devhub.code_review_item3': 'Optimasi Performa',
  'devhub.code_review_item4': 'Saran Peningkatan Khusus',
  'devhub.code_review_submit': 'Kirim Kode untuk Ditinjau',
  // ── Career Simulation ──
  'simulation.subtitle': 'Latih wawancara tiruan dan negosiasi',
  'simulation.history': 'Riwayat Percakapan',
  'simulation.end_button': 'Selesai',
  'simulation.options_title': 'Pilih Mode Simulasi',
  'simulation.options_desc': 'Skenario interaktif dengan perusahaan dan peran nyata di Indonesia',
  'simulation.failed_eval': 'Gagal membuat evaluasi Anda. Silakan coba lagi.',
  'simulation.try_another': 'Coba Simulasi Lain',
  'simulation.interesting_questions': 'Pertanyaan Menarik',
  'simulation.no_history': 'Riwayat simulasi tidak ditemukan. Mulai sesi baru di atas!',
  'simulation.mentor_intro': 'Halo! Saya Mentor AI Anda. Pilih simulasi yang ingin Anda latih hari ini',
  'simulation.salary_negotiation': 'Negosiasi Gaji',
  'simulation.english_interview': 'English Interview',
  'simulation.select_scenario': 'Pilih skenario perusahaan untuk Simulasi Karier.',
  'simulation.select_salary': 'Pilih perusahaan untuk memulai Negosiasi Gaji:',
  'simulation.jobdesk_intro': 'Saya menemukan beberapa lowongan pekerjaan yang cocok dengan profil Anda dari LinkedIn, Jobstreet, dan Glints. Ketuk "Analyze Job" untuk melihat analisis kecocokan keterampilan yang terperinci.',
  'simulation.enter_custom_job': 'Masukkan pekerjaan khusus (mis. Flutter Developer)',
  'simulation.analyze_btn': 'Analisis',
  'simulation.initializing_chat': 'Memulai sesi obrolan mentor...',
  'simulation.ai_responding': 'AI Mentor sedang merespons...',
  'simulation.market_skill_demand': 'Permintaan Keterampilan Pasar',
  'simulation.confidence_threshold': 'Ambang batas keyakinan: ',
  'simulation.matched': 'Cocok',
  'simulation.gap': 'Gap',
  'simulation.analyzing_job_reqs': 'Menganalisis Persyaratan Pekerjaan...',
  'simulation.fetching_db': 'Mengambil database keterampilan pasar untuk prediksi pekerjaan...',
  'simulation.lulus': 'Lulus',
  'simulation.belum_lulus': 'Belum Lulus',
  'simulation.negotiation_completed': 'Negosiasi Selesai',
  'simulation.salary_performance': 'Performa Negosiasi Gaji',
  'simulation.interview_report': 'Laporan Simulasi Wawancara',
  'simulation.evaluation_desc': 'Evaluasi tanggapan Anda oleh AI.',
  'simulation.end_negotiation': 'Akhiri negosiasi',
  'simulation.end_interview': 'Akhiri wawancara',
  // ── Jobdesk Analyzer ──
  'jobdesk.subtitle': 'Tempel deskripsi pekerjaan untuk menganalisis kecocokannya dengan profil Anda.',
  'jobdesk.hint': 'Tempel deskripsi pekerjaan di sini...',
  'jobdesk.button': 'Analisis Deskripsi Pekerjaan',
  'jobdesk.error_empty': 'Silakan tempel deskripsi pekerjaan terlebih dahulu.',
  'jobdesk.error_invalid': 'Judul pekerjaan atau deskripsi tidak valid. Silakan coba dengan peran profesional yang valid.',
  'jobdesk.match_score': 'Kecocokan profil',
  'jobdesk.summary': 'Ringkasan',
  'jobdesk.matching_skills': 'Keterampilan Cocok',
  'jobdesk.missing_skills': 'Keterampilan Kurang',
  'jobdesk.recommendations': 'Rekomendasi',
  // ── Readiness Center ──
  'readiness.subtitle': 'Analisis & ukur kesiapan kerja Anda',
  'readiness.overview': 'Ikhtisar',
  'readiness.initial_test': 'Tes Awal',
  'readiness.skill_map': 'Peta Keterampilan',
  'readiness.skill_gap': 'Kesenjangan Keterampilan',
  'readiness.cv_analysis': 'Analisis CV',
  'readiness.transcript_analysis': 'Analisis Transkrip Akademik',
  'readiness.start_assessment': 'Mulai Asesmen',
  'readiness.retake_test': 'Ulangi Tes',
  'readiness.view_details': 'Lihat Detail',
  'readiness.skills_mapped': 'Keterampilan Dipetakan',
  'readiness.critical_gaps': 'Gaps Kritis',
  'readiness.strengths': 'Kekuatan',
  'readiness.cv_upload_success': 'CV berhasil diunggah dan dianalisis.',
  'readiness.transcript_upload_success': 'Transkrip akademik berhasil diunggah.',
  'readiness.upload_failed': 'Gagal mengunggah. Silakan coba lagi.',
  'readiness.overall_readiness': 'Kesiapan Keseluruhan',
  'readiness.cv_name_empty': 'Belum ada CV diunggah',
  'readiness.cv_desc_present': 'CV Anda telah diunggah dan dianalisis sesuai peran target Anda.',
  'readiness.cv_desc_empty': 'Anda belum mengunggah CV. Unggah sekarang untuk mendapatkan analisis personal tentang keterampilan dan kesenjangan Anda.',
  'readiness.cv_action_upload': 'Unggah CV',
  'readiness.cv_action_reupload': 'Unggah Ulang CV',
  'readiness.transcript_name_empty': 'Belum ada transkrip diunggah',
  'readiness.transcript_desc_present': 'Transkrip akademik Anda telah diunggah dan dianalisis.',
  'readiness.transcript_desc_empty': 'Anda belum mengunggah transkrip akademik. Unggah sekarang untuk menyertakan performa akademik Anda ke dalam skor kesiapan.',
  'readiness.transcript_action_upload': 'Unggah Transkrip Akademik',
  'readiness.transcript_action_reupload': 'Unggah Ulang Transkrip Akademik',
  'readiness.banner_title': 'Periksa CV Anda Sekarang',
  'readiness.banner_desc': 'Penasaran bagaimana performa CV Anda di mata perekrut? Unggah sekarang dan biarkan AI memberikan wawasan instan serta tips peningkatan.',
  'readiness.uploading': 'Mengunggah...',
  'readiness.sign_in_required': 'Silakan masuk kembali untuk mengunggah dokumen.',
  'readiness.initial_test_title': 'Asesmen Keterampilan Awal',
  'readiness.initial_test_desc': 'Lengkapi analisis CV dan GitHub Anda dengan asesmen pengetahuan langsung. Tes ini mengevaluasi keterampilan Anda di seluruh kategori yang dipetakan peran untuk memberikan skor kesiapan yang akurat.',
  'readiness.stats_questions': 'Pertanyaan',
  'readiness.stats_questions_val': 'Kumpulan dinamis',
  'readiness.stats_duration': 'Durasi',
  'readiness.stats_duration_val': '~10 Menit',
  'readiness.stats_targeted': 'Tertarget',
  'readiness.stats_targeted_val': 'Selaras peran',
  'readiness.helps_title': 'Bagaimana ini membantu skor kesiapan Anda',
  'readiness.helps_desc': 'Mengikuti asesmen ini menambahkan dimensi evaluasi ketiga ke aktivitas CV dan GitHub Anda, membuat analisis Peta Keterampilan dan Kesenjangan Keterampilan Anda jauh lebih akurat.',
  'readiness.score': 'Skor',
  'readiness.result_excellent': 'Kerja Luar Biasa!',
  'readiness.result_good': 'Terus Berlatih!',
  'readiness.result_focus': 'Fokus & Tingkatkan!',
  'readiness.completed_on': 'Selesai pada ',
  'readiness.recently': 'baru-baru ini',
  'readiness.status_ready': 'Siap / Lulus',
  'readiness.status_developing': 'Berkembang',
  'readiness.status_needs_focus': 'Butuh Fokus',
  'readiness.skill_map_title': 'Peta Keterampilan Anda',
  'readiness.skill_details_title': 'Detail Keterampilan Anda',
  'readiness.skill_level': 'Level: ',
  'readiness.gap_to_learn': 'Perlu Dipelajari',
  'readiness.gap_to_improve': 'Perlu Ditingkatkan',
  'readiness.gap_already_strong': 'Sudah Kuat',
  'readiness.desc_to_learn': 'Kesenjangan prioritas tinggi • Permintaan perekrut: kritis',
  'readiness.desc_to_improve': 'Kesenjangan prioritas sedang • Permintaan perekrut: moderat',
  'readiness.desc_already_strong': 'Kompetensi tinggi • Permintaan perekrut: terpenuhi',
  'readiness.market_demand': 'Top Industry Skills',
  'devhub.skill_map_empty_title': 'Skill Map Belum Tersedia',
  'devhub.skill_map_empty_desc': 'Selesaikan Initial Test terlebih dahulu untuk melihat peta keahlian Anda.',
  'devhub.start_initial_test': 'Mulai Initial Test',
};

const Map<String, String> _jp = {
  // ── Appearance / settings ──
  'settings.appearance': '言語と外観',
  'appearance.title': '言語と外観',
  'appearance.subtitle': 'アプリのテーマと言語をカスタマイズ',
  'appearance.language': '言語',
  'appearance.theme': 'テーマ',
  'theme.light': 'ライト',
  'theme.dark': 'ダーク',
  'theme.system': 'システム',
  // ── Bottom nav ──
  'nav.home': 'ホーム',
  'nav.readiness': '準備',
  'nav.devhub': '開発ハブ',
  'nav.simulation': 'シミュレーション',
  'nav.profile': 'プロフィール',
  // ── Search ──
  'search.hint': '機能を検索...',
  'search.empty': '機能が見つかりません',
  // ── Common ──
  'common.view_all': 'すべて表示',
  'common.loading': '読み込み中...',
  'common.analyzing': '分析中...',
  'common.progress': '進捗',
  'common.continue': '続ける',
  'common.save': '保存',
  'common.save_changes': '変更を保存',
  'common.cancel': 'キャンセル',
  'common.back': '戻る',
  'common.skip_for_now': '今はスキップ',
  'common.user': 'ユーザー',
  'common.retry': '再試行',
  // ── Skill statuses ──
  'status.weak': '弱い',
  'status.enough': '十分',
  'status.strong': '強い',
  // ── Full feature names ──
  'feature.readiness': '準備センター',
  'feature.devhub': '開発ハブ',
  'feature.simulation': 'キャリアシミュレーション',
  'feature.jobdesk': '求人アナライザー',
  // ── Home ──
  'home.welcome_back': 'おかえりなさい！',
  'home.skills_attention': '注意が必要なスキル',
  'home.great_job': 'よくできました！',
  'home.skills_all_strong': 'すべてのスキルが強く、必要な役割の基準を満たしています。',
  'home.achievement_progress': 'あなたの達成状況',
  'home.quick_actions': 'クイックアクション',
  'home.take_initial': '初期評価を受ける',
  'home.boost_accuracy': '準備の精度を高めましょう',
  'home.upcoming_tasks': '今後のタスク',
  'home.growth_progress': '成長の進捗',
  'home.this_month': '今月',
  'home.skills_mapped': 'マッピング済みスキル',
  'home.projects_done': '完了したプロジェクト',
  'home.simulations': 'シミュレーション',
  'home.continue_working': '作業を続ける',
  'home.nothing_progress': 'まだ進行中のものはありません。\nプロジェクトやシミュレーションを始めるとここに表示されます。',
  'home.recently_visited': '最近アクセスした',
  'home.data_footer': '2,847件以上のアクティブな求人データ • 6時間ごとに更新',
  'home.readiness_index': '本日のあなたの準備指数',
  'home.growing': '成長中',
  'home.predicted_role': '予測される役割:',
  'home.up_last_week': '↑ 先週より上昇',
  'home.day_streak': '本日の連続日数',
  'home.career_seeker': 'キャリア志望者',
  'home.failed_skills': 'スキルの読み込みに失敗しました',
  'home.error_profile': 'プロフィールの読み込みエラー',
  'common.recent': '最近',
  // ── Profile ──
  'profile.title': 'プロフィール',
  'profile.tab_my': 'マイプロフィール',
  'profile.tab_settings': '設定',
  'profile.role_default': 'フロントエンド開発者',
  'profile.stat_readiness': '準備\n指数',
  'profile.stat_gaps': '改善が必要な\nスキル',
  'profile.stat_projects': 'ミニ\nプロジェクト',
  'profile.stat_tests': 'スキルテスト\n回数',
  'profile.validated_competitions': '認定された能力',
  'profile.no_competitions': 'まだ認定された実績はありません',
  'profile.no_competitions_desc':
      'Dev Hub でミニプロジェクトを完了するか、Readiness Center で評価を受けて、検証済みスキルバッジを取得しましょう。',
  'profile.skill_details': 'スキルの詳細',
  'profile.documents': 'ドキュメント',
  'profile.no_documents': 'まだドキュメントがアップロードされていません',
  'profile.transcript': '成績証明書',
  'profile.upload_cv': '履歴書をアップロード',
  'profile.replace_cv': '履歴書を差し替え',
  'profile.upload_transcript': '成績証明書をアップロード',
  'profile.replace_transcript': '成績証明書を差し替え',
  'profile.cannot_read_file': '選択したファイルを読み取れませんでした',
  'profile.upload_failed': 'アップロードに失敗しました',
  'profile.cannot_open_doc': 'ドキュメントを開けませんでした',
  'profile.doc_uploaded_suffix': 'を正常にアップロードしました',
  'profile.account_settings': 'アカウント設定',
  'profile.preferences': '環境設定',
  'profile.integrations_support': '連携とサポート',
  'profile.personal_info': '個人情報',
  'profile.password_security': 'パスワードとセキュリティ',
  'profile.notifications': '通知',
  'profile.integrations': '連携',
  'profile.help_support': 'ヘルプとサポート',
  'profile.logout': 'ログアウト',
  // ── DevHub ──
  'devhub.subtitle': 'スキルと就職準備度を向上させる',
  'devhub.mini_project': 'ミニプロジェクト',
  'devhub.code_review': 'コードレビュー',
  'devhub.skill_map': 'スキルマップ',
  'devhub.projects_for_you': 'あなた向けのミニプロジェクト',
  'devhub.no_projects': '利用可能なプロジェクトはまだありません。',
  'devhub.not_submitted': 'まだ提出されていません',
  'devhub.code_review_title': 'AIコードレビュー',
  'devhub.code_review_desc': 'ミニプロジェクトのコードを提出し、シニア開発者のコードレビューのような具体的なフィードバックを受け取ります。',
  'devhub.code_review_item1': 'クリーンコードとベストプラクティス',
  'devhub.code_review_item2': 'エラーハンドリング',
  'devhub.code_review_item3': 'パフォーマンスの最適化',
  'devhub.code_review_item4': '具体的な改善の提案',
  'devhub.code_review_submit': 'コードを提出してレビューを受ける',
  // ── Career Simulation ──
  'simulation.subtitle': '模擬面接と交渉の練習',
  'simulation.history': '会話履歴',
  'simulation.end_button': '終了',
  'simulation.options_title': 'シミュレーションモードを選択',
  'simulation.options_desc': 'インドネシアの実際の企業や役割とのインタラクティブなシナリオ',
  'simulation.failed_eval': '評価レポートを生成できませんでした。もう一度お試しください。',
  'simulation.try_another': '別のシミュレーションを試す',
  'simulation.interesting_questions': '興味深い質問',
  'simulation.no_history': 'シミュレーション履歴が見つかりません。上で新しいセッションを開始してください！',
  'simulation.mentor_intro': 'こんにちは！私はあなたのAIメンターです。今日練習したいシミュレーションを選択してください',
  'simulation.salary_negotiation': '給与交渉',
  'simulation.english_interview': 'English Interview',
  'simulation.select_scenario': 'キャリアシミュレーションの企業シナリオを選択してください。',
  'simulation.select_salary': '給与交渉を開始する企業を選択してください：',
  'simulation.jobdesk_intro': 'LinkedIn、Jobstreet、Glintsからあなたのプロフィールに一致するいくつかの求人情報が見つかりました。「求人を分析」をタップして、詳細なスキルマッチ分析を確認してください。',
  'simulation.enter_custom_job': 'カスタムジョブを入力（例: Flutter Developer）',
  'simulation.analyze_btn': '分析する',
  'simulation.initializing_chat': 'メンターチャットセッションを初期化中...',
  'simulation.ai_responding': 'AIメンターが返信しています...',
  'simulation.market_skill_demand': '市場のスキル需要',
  'simulation.confidence_threshold': '信頼度のしきい値: ',
  'simulation.matched': 'マッチ',
  'simulation.gap': 'ギャップ',
  'simulation.analyzing_job_reqs': '求人要件を分析中...',
  'simulation.fetching_db': '求人予測のために市場スキルデータベースを取得中...',
  'simulation.lulus': '合格',
  'simulation.belum_lulus': '不合格',
  'simulation.negotiation_completed': '交渉完了',
  'simulation.salary_performance': '給与交渉のパフォーマンス',
  'simulation.interview_report': '面接シミュレーションレポート',
  'simulation.evaluation_desc': '回答に対するAIによる自動評価。',
  'simulation.end_negotiation': '交渉を終了',
  'simulation.end_interview': '面接を終了',
  // ── Jobdesk Analyzer ──
  'jobdesk.subtitle': '求人説明を貼り付けて、プロフィールとの一致度を分析します。',
  'jobdesk.hint': '求人説明をここに貼り付け...',
  'jobdesk.button': '求人説明を分析',
  'jobdesk.error_empty': '最初に求人説明を貼り付けてください。',
  'jobdesk.error_invalid': '無効な職種名または説明です。有効な専門職の役割でお試しください。',
  'jobdesk.match_score': 'プロフィールのマッチ度',
  'jobdesk.summary': '要約',
  'jobdesk.matching_skills': 'マッチするスキル',
  'jobdesk.missing_skills': '不足しているスキル',
  'jobdesk.recommendations': '推奨事項',
  // ── Readiness Center ──
  'readiness.subtitle': '仕事への準備度を分析・測定する',
  'readiness.overview': '概要',
  'readiness.initial_test': '初期テスト',
  'readiness.skill_map': 'スキルマップ',
  'readiness.skill_gap': 'スキルギャップ',
  'readiness.cv_analysis': '履歴書分析',
  'readiness.transcript_analysis': '成績証明書分析',
  'readiness.start_assessment': 'アセスメントを開始',
  'readiness.retake_test': 'テストを再受ける',
  'readiness.view_details': '詳細を表示',
  'readiness.skills_mapped': 'マッピング済みスキル',
  'readiness.critical_gaps': '致命的なギャップ',
  'readiness.strengths': '強み',
  'readiness.cv_upload_success': '履歴書のアップロードと分析が正常に完了しました。',
  'readiness.transcript_upload_success': '成績証明書が正常にアップロードされました。',
  'readiness.upload_failed': 'アップロードに失敗しました。もう一度お試しください。',
  'readiness.overall_readiness': '全体的な準備度',
  'readiness.cv_name_empty': '履歴書が未アップロードです',
  'readiness.cv_desc_present': 'あなたの履歴書はアップロードされ、ターゲットの役割に対して分析されました。',
  'readiness.cv_desc_empty': '履歴書はまだアップロードされていません。アップロードして、スキルとギャップのパーソナライズされた分析を取得します。',
  'readiness.cv_action_upload': '履歴書をアップロード',
  'readiness.cv_action_reupload': '履歴書を再アップロード',
  'readiness.transcript_name_empty': '成績証明書が未アップロードです',
  'readiness.transcript_desc_present': 'あなたの成績証明書はアップロードされ、分析されました。',
  'readiness.transcript_desc_empty': '成績証明書はまだアップロードされていません。アップロードして、準備スコアに学業成績を含めます。',
  'readiness.transcript_action_upload': '成績証明書をアップロード',
  'readiness.transcript_action_reupload': '成績証明書を再アップロード',
  'readiness.banner_title': '今すぐ履歴書をチェック',
  'readiness.banner_desc': '採用担当者の前であなたの履歴書がどのように機能するか気になりますか？アップロードして、AIから即座にインサイトと改善のヒントを得ましょう。',
  'readiness.uploading': 'アップロード中...',
  'readiness.sign_in_required': 'ドキュメントをアップロードするには、再度サインインしてください。',
  'readiness.initial_test_title': '初期スキル評価',
  'readiness.initial_test_desc': '直接の知識評価で履歴書とGitHubの分析を補完します。このテストは、役割にマッピングされたカテゴリ全体でスキルを評価し、正確な準備スコアを提供します。',
  'readiness.stats_questions': '質問',
  'readiness.stats_questions_val': '動的プール',
  'readiness.stats_duration': '所要時間',
  'readiness.stats_duration_val': '約10分',
  'readiness.stats_targeted': 'ターゲット型',
  'readiness.stats_targeted_val': '役割に準拠',
  'readiness.helps_title': 'これが準備スコアにどのように役立つか',
  'readiness.helps_desc': 'この評価を受けることで、履歴書とGitHubのアクティビティに3番目の評価ディメンションが追加され、スキルマップとスキルギャップの分析が大幅に正確になります。',
  'readiness.score': 'スコア',
  'readiness.result_excellent': '素晴らしい出来です！',
  'readiness.result_good': '練習を続けましょう！',
  'readiness.result_focus': '集中して改善しましょう！',
  'readiness.completed_on': '完了日: ',
  'readiness.recently': '最近',
  'readiness.status_ready': '準備完了 / 合格',
  'readiness.status_developing': '開発中',
  'readiness.status_needs_focus': '要注力',
  'readiness.skill_map_title': 'スキルマップ',
  'readiness.skill_details_title': 'スキルの詳細',
  'readiness.skill_level': 'レベル: ',
  'readiness.gap_to_learn': '学習が必要',
  'readiness.gap_to_improve': '改善が必要',
  'readiness.gap_already_strong': 'すでに強み',
  'readiness.desc_to_learn': '優先度の高いギャップ • 採用ニーズ: 非常に高い',
  'readiness.desc_to_improve': '優先度中程度のギャップ • 採用ニーズ: 中程度',
  'readiness.desc_already_strong': '高い習熟度 • 採用ニーズ: 充足',
  'readiness.market_demand': '市場のニーズ',
};

Map<String, String> _dictionaryFor(AppLanguage lang) {
  switch (lang) {
    case AppLanguage.id:
      return _id;
    case AppLanguage.jp:
      return _jp;
    case AppLanguage.enUs:
    case AppLanguage.enUk:
      return _en;
  }
}

/// Translate [key] for [lang], falling back to English then the raw key.
String appTranslate(AppLanguage lang, String key) {
  return _dictionaryFor(lang)[key] ?? _en[key] ?? key;
}

/// Holds the app-wide [AppLanguage] and persists the user's choice across
/// launches via shared_preferences. Mirrors the website's LanguageProvider,
/// which stores the same code under localStorage('wirapath-language').
class LanguageNotifier extends Notifier<AppLanguage> {
  static const String _prefsKey = 'app_language';

  @override
  AppLanguage build() {
    Future.microtask(_load);
    return AppLanguage.enUs;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null) {
        state = AppLanguageX.fromCode(saved);
      }
    } catch (_) {
      // Ignore — keep the default English (US).
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, language.code);
    } catch (_) {
      // Persistence is best-effort.
    }
  }
}

final languageProvider =
    NotifierProvider<LanguageNotifier, AppLanguage>(LanguageNotifier.new);

/// Convenience for widgets: `ref.tr('nav.home')` style access.
extension LanguageRef on Ref {
  String tr(String key) => appTranslate(read(languageProvider), key);
}
