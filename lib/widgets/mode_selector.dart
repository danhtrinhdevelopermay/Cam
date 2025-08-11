import 'package:flutter/material.dart';
import 'dart:ui';

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: modes.length,
              itemBuilder: (context, index) {
                final mode = modes[index];
                final isSelected = currentMode.toUpperCase() == mode;
                
                return GestureDetector(
                  onTap: () => onModeChanged(mode.toLowerCase()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Center(
                      child: Text(
                        mode,
                        style: TextStyle(
                          color: isSelected 
                              ? Colors.yellow 
                              : Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: isSelected 
                              ? FontWeight.w600 
                              : FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}