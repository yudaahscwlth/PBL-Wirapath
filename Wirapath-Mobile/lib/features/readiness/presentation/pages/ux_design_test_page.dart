import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class UXDesignTestPage extends StatelessWidget {
  const UXDesignTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => context.go('/readiness-center', extra: {'initialTabIndex': 1}),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                "User Experience Design",
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEC85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "HCEV",
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Design Brief • Portfolio Upload',
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Design Brief',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDesignBriefBox(),
                    const SizedBox(height: 32),

                    Text(
                      'Upload Mockup or Prototype',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildUploadArea(context),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          context.push('/readiness-center/ux-design-review');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF066EFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Submit',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesignBriefBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB5E0FF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You are a UX designer at a fintech startup launching a personal finance app targeting young professionals aged 22–35. The product team has identified a key problem: users abandon the app within the first week because the onboarding feels overwhelming and they don\'t understand the app\'s core value.\nYour task:\n\nDesign the onboarding experience for this app. Your submission must include:\n\n1. User persona — define one target user (name, age, goals, pain points, tech comfort level).\n2. User flow — map out the full onboarding journey from app launch to first meaningful action (e.g., connecting a bank account or setting a budget goal). Minimum 6 steps.\n3. Wireframes — low or mid-fidelity screens for at least 5 key screens in the onboarding flow.\n4. Prototype — a clickable prototype (Figma preferred) demonstrating the primary onboarding path.\n5. Design rationale — a written section (100–150 words) explaining your key design decisions, especially how you addressed the abandonment problem.\n\nEvaluation criteria: Clarity of user flow, visual hierarchy, accessibility considerations, quality of rationale.\nUpload your complete work as a .fig file, .pdf export, or .zip containing all assets.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF333333),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadArea(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF9CA3AF),
          style: BorderStyle.solid,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFE5F1FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_upload_outlined,
              color: Color(0xFF066EFF),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Upload File',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Supports .fig .pdf .zip (Max 10 MB)',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
