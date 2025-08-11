import 'package:flutter/material.dart';
import 'dart:ui';

enum CameraAspectRatio {
  square('1:1', 1.0),
  ratio4_3('4:3', 4.0 / 3.0),
  ratio16_9('16:9', 16.0 / 9.0),
  full('Full', 0.0); // 0.0 indicates full screen

  const CameraAspectRatio(this.label, this.value);
  final String label;
  final double value;
}

class AspectRatioSelector extends StatelessWidget {
  final CameraAspectRatio selectedRatio;
  final Function(CameraAspectRatio) onRatioChanged;

  const AspectRatioSelector({
    super.key,
    required this.selectedRatio,
    required this.onRatioChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: CameraAspectRatio.values.map((ratio) {
                final isSelected = ratio == selectedRatio;
                return GestureDetector(
                  onTap: () => onRatioChanged(ratio),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? Colors.yellow.withOpacity(0.9)
                        : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ratio.label,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class AspectRatioOverlay extends StatelessWidget {
  final CameraAspectRatio aspectRatio;
  final Size screenSize;
  final Widget child;

  const AspectRatioOverlay({
    super.key,
    required this.aspectRatio,
    required this.screenSize,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (aspectRatio == CameraAspectRatio.full) {
      return child;
    }

    final targetAspectRatio = aspectRatio.value;
    final screenAspectRatio = screenSize.width / screenSize.height;
    
    double overlayWidth = screenSize.width;
    double overlayHeight = screenSize.height;
    
    if (targetAspectRatio > screenAspectRatio) {
      // Fit to width
      overlayHeight = overlayWidth / targetAspectRatio;
    } else {
      // Fit to height  
      overlayWidth = overlayHeight * targetAspectRatio;
    }

    final topBottomOverlay = (screenSize.height - overlayHeight) / 2;
    final leftRightOverlay = (screenSize.width - overlayWidth) / 2;

    return Stack(
      children: [
        child,
        // Top overlay
        if (topBottomOverlay > 0)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topBottomOverlay,
            child: Container(
              color: Colors.black.withOpacity(0.7),
            ),
          ),
        // Bottom overlay
        if (topBottomOverlay > 0)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: topBottomOverlay,
            child: Container(
              color: Colors.black.withOpacity(0.7),
            ),
          ),
        // Left overlay
        if (leftRightOverlay > 0)
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: leftRightOverlay,
            child: Container(
              color: Colors.black.withOpacity(0.7),
            ),
          ),
        // Right overlay
        if (leftRightOverlay > 0)
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: leftRightOverlay,
            child: Container(
              color: Colors.black.withOpacity(0.7),
            ),
          ),
        // Aspect ratio indicator lines
        if (aspectRatio != CameraAspectRatio.full)
          Positioned(
            top: topBottomOverlay > 0 ? topBottomOverlay : leftRightOverlay,
            left: leftRightOverlay > 0 ? leftRightOverlay : topBottomOverlay,
            child: Container(
              width: overlayWidth,
              height: overlayHeight,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}