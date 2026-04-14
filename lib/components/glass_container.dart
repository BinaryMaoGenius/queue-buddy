import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Border? border;
  final double opacity;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.blur = 12,
    this.color,
    this.border,
    this.opacity = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: (color ?? AppColors.glassBase).withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? Border.all(color: AppColors.glassBorder, width: 1.5),
            gradient: AppColors.glassGradient,
          ),
          child: child,
        ),
      ),
    );
  }
}

