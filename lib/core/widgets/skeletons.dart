import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SkeletonCard extends StatelessWidget {
  final double height;
  const SkeletonCard({super.key, this.height = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.lightGray.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 56,
            color: AppColors.lightGray.withValues(alpha: 0.08),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 120,
                  color: AppColors.lightGray.withValues(alpha: 0.08),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  width: 80,
                  color: AppColors.lightGray.withValues(alpha: 0.06),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
