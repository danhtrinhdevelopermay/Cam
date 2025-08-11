import 'dart:ui';
import 'package:flutter/material.dart';

class BlurOverlay extends StatelessWidget {
  final double sigmaX;
  final double sigmaY;
  final Widget? child;

  const BlurOverlay({
    super.key,
    required this.sigmaX,
    required this.sigmaY,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (sigmaX == 0 && sigmaY == 0) {
      return child ?? const SizedBox.shrink();
    }

    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: sigmaX,
        sigmaY: sigmaY,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
        ),
        child: child,
      ),
    );
  }
}

class GlassEffect extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;

  const GlassEffect({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.2,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: (color ?? Colors.white).withOpacity(opacity),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}