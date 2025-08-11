import 'package:flutter/material.dart';
import 'dart:ui';
import '../camera/advanced_zoom_controller.dart';
import 'blur_overlay.dart';

/// Advanced zoom controls widget with 10x zoom capabilities
/// Provides UI for optical zoom, digital zoom, and enhancement method selection
class AdvancedZoomControls extends StatefulWidget {
  final AdvancedZoomController zoomController;
  final Function(double) onZoomChanged;
  final VoidCallback? onCapturePressed;

  const AdvancedZoomControls({
    super.key,
    required this.zoomController,
    required this.onZoomChanged,
    this.onCapturePressed,
  });

  @override
  State<AdvancedZoomControls> createState() => _AdvancedZoomControlsState();
}

class _AdvancedZoomControlsState extends State<AdvancedZoomControls>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  // Zoom levels for quick selection (iOS 18 style)
  final List<double> quickZoomLevels = [1.0, 2.0, 5.0, 10.0];
  bool _showZoomSlider = false;
  bool _showEnhancementSettings = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Enhancement Settings Panel (expandable)
          if (_showEnhancementSettings) _buildEnhancementSettings(),
          
          // Compact Main Controls Row
          Row(
            children: [
              // Zoom Method Status (left side)
              Expanded(child: _buildCompactZoomStatus()),
              
              const SizedBox(width: 12),
              
              // Main Camera Controls (right side)
              _buildCompactMainControls(),
            ],
          ),
          
          // Zoom Slider (expandable)
          if (_showZoomSlider) _buildZoomSlider(),
          
          const SizedBox(height: 16),
          
          // Enhanced Capture Button
          _buildEnhancedCaptureButton(),
        ],
      ),
    );
  }

  /// Get appropriate icon for current zoom method
  IconData _getZoomMethodIcon() {
    final controller = widget.zoomController;
    
    if (controller.currentZoomLevel <= controller.maxOpticalZoom && 
        controller.opticalZoomEnabled) {
      return Icons.camera_alt; // Optical zoom
    } else if (controller.highResolutionCropEnabled) {
      return Icons.crop; // High-res crop
    } else if (controller.aiSuperResolutionEnabled) {
      return Icons.auto_awesome; // AI enhancement
    } else {
      return Icons.zoom_in; // Digital zoom
    }
  }



  /// Build expandable zoom slider for precise control
  Widget _buildZoomSlider() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      '1x',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Expanded(
                      child: Slider(
                        value: widget.zoomController.currentZoomLevel,
                        min: 1.0,
                        max: widget.zoomController.maxDigitalZoom,
                        divisions: 90, // 0.1x precision
                        activeColor: Colors.yellow,
                        inactiveColor: Colors.white.withOpacity(0.3),
                        thumbColor: Colors.yellow,
                        onChanged: (value) {
                          widget.onZoomChanged(value);
                          setState(() {});
                        },
                      ),
                    ),
                    Text(
                      '${widget.zoomController.maxDigitalZoom.toInt()}x',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
                
                // Zoom level display
                Text(
                  '${widget.zoomController.currentZoomLevel.toStringAsFixed(1)}x',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build enhancement settings panel
  Widget _buildEnhancementSettings() {
    final controller = widget.zoomController;
    final capabilities = controller.getCapabilitiesSummary();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Zoom Enhancement Methods',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Device capabilities info
                if (!capabilities['hasOpticalZoom'])
                  _buildCapabilityWarning('No optical zoom hardware detected'),
                
                // Enhancement method toggles
                _buildEnhancementToggle(
                  'High-Resolution Crop',
                  'Crop from ${capabilities['sensorResolutionMP'].toStringAsFixed(1)}MP sensor',
                  controller.highResolutionCropEnabled,
                  (value) => setState(() => controller.highResolutionCropEnabled = value),
                  true,
                ),
                

                _buildEnhancementToggle(
                  'AI Super Resolution',
                  'Requires internet connection',
                  controller.aiSuperResolutionEnabled,
                  (value) => setState(() => controller.aiSuperResolutionEnabled = value),
                  false, // Disabled by default due to performance
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build individual enhancement method toggle
  Widget _buildEnhancementToggle(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    bool recommended,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (recommended)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'REC',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.yellow,
            inactiveThumbColor: Colors.white.withOpacity(0.7),
            inactiveTrackColor: Colors.white.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  /// Build capability warning
  Widget _buildCapabilityWarning(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.orange,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build enhanced capture button with animation
  Widget _buildEnhancedCaptureButton() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _animationController.forward(),
            onTapUp: (_) => _animationController.reverse(),
            onTapCancel: () => _animationController.reverse(),
            onTap: widget.onCapturePressed,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.yellow,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Inner circle with enhanced indicator
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.yellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                  
                  // Enhanced capture indicator
                  Positioned(
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${widget.zoomController.currentZoomLevel.toStringAsFixed(1)}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build compact zoom status for reorganized layout with iOS 18 styling
  Widget _buildCompactZoomStatus() {
    return iOS18GlassEffect(
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      blur: 15.0,
      opacity: 0.3,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getZoomMethodIcon(),
            size: 14,
            color: Colors.white.withOpacity(0.9),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              widget.zoomController.getCurrentZoomMethodDescription(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              setState(() {
                _showEnhancementSettings = !_showEnhancementSettings;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: _showEnhancementSettings 
                  ? Colors.yellow.withOpacity(0.2) 
                  : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.settings,
                size: 14,
                color: _showEnhancementSettings 
                  ? Colors.yellow 
                  : Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build compact main controls for reorganized layout
  Widget _buildCompactMainControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Quick zoom buttons (horizontal row)
        ...quickZoomLevels.map((zoomLevel) {
          final isSelected = (widget.zoomController.currentZoomLevel - zoomLevel).abs() < 0.1;
          return GestureDetector(
            onTap: () {
              widget.onZoomChanged(zoomLevel);
              setState(() {});
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.yellow.withOpacity(0.9) : Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.yellow : Colors.white.withOpacity(0.3),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ] : [],
              ),
              child: Text(
                '${zoomLevel.toInt()}x',
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
        
        const SizedBox(width: 8),
        
        // Zoom slider toggle
        GestureDetector(
          onTap: () {
            setState(() {
              _showZoomSlider = !_showZoomSlider;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _showZoomSlider ? Colors.yellow.withOpacity(0.9) : Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _showZoomSlider ? Colors.yellow : Colors.white.withOpacity(0.3),
                width: _showZoomSlider ? 2 : 1,
              ),
              boxShadow: _showZoomSlider ? [
                BoxShadow(
                  color: Colors.yellow.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ] : [],
            ),
            child: Icon(
              Icons.tune,
              size: 16,
              color: _showZoomSlider ? Colors.yellow : Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}