import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class PulseBarWidget extends StatelessWidget {
  final int waitingCount;
  final int maxCapacity;

  const PulseBarWidget({
    super.key, 
    required this.waitingCount, 
    this.maxCapacity = 50,
  });

  @override
  Widget build(BuildContext context) {
    double progress = (waitingCount / maxCapacity).clamp(0.05, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            children: [
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutQuart,
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.premiumGradient,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

