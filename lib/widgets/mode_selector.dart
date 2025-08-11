import 'package:flutter/material.dart';
import 'blur_overlay.dart';

class ModeSelector extends StatelessWidget {
  final String currentMode;
  final Function(String) onModeChanged;

  const ModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  static const List<String> modes = [
    'TIME-LAPSE',
    'SLO-MO',
    'VIDEO',
    'PHOTO',
    'PORTRAIT',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassEffect(
        borderRadius: BorderRadius.circular(20),
        blur: 20.0,
        opacity: 0.25,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: modes.length,
          itemBuilder: (context, index) {
            final mode = modes[index];
            final isSelected = currentMode.toUpperCase() == mode;
            
            return GestureDetector(
              onTap: () => onModeChanged(mode.toLowerCase()),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.yellow.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    mode,
                    style: TextStyle(
                      color: isSelected 
                          ? Colors.yellow 
                          : Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: isSelected 
                          ? FontWeight.w700 
                          : FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}