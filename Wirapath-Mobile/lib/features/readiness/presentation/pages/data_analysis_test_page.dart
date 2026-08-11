import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class DataAnalysisTestPage extends StatelessWidget {
  const DataAnalysisTestPage({super.key});

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
                "Data Analysis",
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
                "DTAN",
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
                      'File Upload • Short Essay',
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Practical Task',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoBox(
                      'You are given a retail sales dataset (sales_data.csv) containing: date, product_id, category, region, units_sold, unit_price, discount, customer_segment.\n\n'
                      'Complete the following in a Jupyter notebook or Excel and upload your file:\n\n'
                      '1. Clean the dataset — identify and handle missing values, duplicates, and outliers. Document your approach.\n'
                      '2. Calculate total revenue per category per month. Which category performed best in Q3?\n'
                      '3. Compute the average discount rate per customer segment. Does higher discount correlate with higher units sold?\n'
                      '4. Identify the top 5 products by revenue in the "North" region.\n'
                      '5. Create at least 2 visualizations: one showing monthly revenue trend, one showing category breakdown by region.\n'
                      '6. Build a simple linear regression model to predict units_sold based on unit_price and discount. Report R² and interpret the result.',
                    ),
                    const SizedBox(height: 32),

                    Text(
                      'Upload The Analysis Results',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildUploadArea(context),
                    const SizedBox(height: 32),

                    Text(
                      'Interpretation Essay',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoBox(
                      'Based on your analysis above, answer the following in 150-250 words:\n'
                      '• What is the most significant business insight you found?\n'
                      '• Which customer segment should the company prioritize, and why?\n'
                      '• What are the limitations of your analysis, and what additional data would improve it?',
                    ),
                    const SizedBox(height: 32),

                    Text(
                      'Interpretation of Results',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextInputArea(context),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          context.push('/readiness-center/data-analysis-review');
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

  Widget _buildInfoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF2FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB5E0FF)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(0xFF333333),
          height: 1.6,
        ),
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
          style: BorderStyle.solid, // Flutter doesn't have a built-in dashed border easily, but we can simulate or use a package. For now, solid with custom look.
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
            'Supports .csv .xlsx .ipynb (Max 10 MB)',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        maxLines: 6,
        decoration: InputDecoration(
          hintText: 'Write the main insights from your analysis',
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF9CA3AF),
            fontStyle: FontStyle.italic,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
