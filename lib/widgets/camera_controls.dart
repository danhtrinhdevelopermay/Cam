import 'package:flutter/material.dart';
import 'dart:ui';

class CameraControls extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onCapturePressed;
  final VoidCallback onSwitchCamera;
  final Function(double) onZoomChanged;
  final double minZoom;
  final double maxZoom;
  final double currentZoom;

  const CameraControls({
    super.key,
    required this.isRecording,
    required this.onCapturePressed,
    required this.onSwitchCamera,
    required this.onZoomChanged,
    required this.minZoom,
    required this.maxZoom,
    required this.currentZoom,
  });

  @override
  State<CameraControls> createState() => _CameraControlsState();
}

class _CameraControlsState extends State<CameraControls>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Gallery Button
          GestureDetector(
            onTap: () {
              // TODO: Open gallery
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Capture Button
          GestureDetector(
            onTapDown: (_) => _animationController.forward(),
            onTapUp: (_) {
              _animationController.reverse();
              widget.onCapturePressed();
            },
            onTapCancel: () => _animationController.reverse(),
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isRecording ? Colors.red : Colors.white,
                          border: Border.all(
                            color: Colors.black.withOpacity(0.1),
                            width: 2,
                          ),
                        ),
                        child: widget.isRecording
                            ? const Icon(
                                Icons.stop,
                                color: Colors.white,
                                size: 32,
                              )
                            : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Switch Camera Button
          GestureDetector(
            onTap: widget.onSwitchCamera,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.flip_camera_ios,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}