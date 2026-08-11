import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class WebcamPreview extends StatelessWidget {
  const WebcamPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBlue.withOpacity(0.1),
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3), width: 1.5),
            ),
            child: const Icon(
              Icons.face_retouching_natural_rounded,
              color: AppColors.primaryBlue,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Live Video Stream',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
