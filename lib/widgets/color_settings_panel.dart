import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../camera/color_processing_controller.dart';
import '../camera/hdr_capture_controller.dart';
import 'blur_overlay.dart';

class ColorSettingsPanel extends StatefulWidget {
  final ColorProcessingController colorController;
  final HdrCaptureController hdrController;
  final VoidCallback onClose;

  const ColorSettingsPanel({
    super.key,
    required this.colorController,
    required this.hdrController,
    required this.onClose,
  });

  @override
  State<ColorSettingsPanel> createState() => _ColorSettingsPanelState();
}

class _ColorSettingsPanelState extends State<ColorSettingsPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closePanel() {
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Background overlay
            Positioned.fill(
              child: GestureDetector(
                onTap: _closePanel,
                child: Container(
                  color: Colors.black.withOpacity(0.3 * _fadeAnimation.value),
                ),
              ),
            ),
            
            // Settings panel
            Positioned(
              right: 16,
              top: 100 + (MediaQuery.of(context).size.height * 0.3 * _slideAnimation.value),
              child: Transform.translate(
                offset: Offset(300 * _slideAnimation.value, 0),
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: _buildSettingsPanel(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsPanel() {
    return Container(
      width: 280,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: GlassEffect(
        blur: 15,
        opacity: 0.9,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Color Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: _closePanel,
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HDR Settings
                      _buildSectionHeader('HDR & Color Space'),
                      _buildToggleSetting(
                        'HDR Capture',
                        'Multi-frame HDR with gain maps',
                        widget.hdrController.hdrEnabled,
                        (value) {
                          setState(() {
                            widget.hdrController.hdrEnabled = value;
                          });
                        },
                      ),
                      
                      _buildToggleSetting(
                        'Display P3',
                        'Wide color gamut for vivid colors',
                        widget.colorController.displayP3Enabled,
                        (value) {
                          setState(() {
                            widget.colorController.displayP3Enabled = value;
                          });
                        },
                      ),
                      
                      _buildToggleSetting(
                        'Adaptive HDR',
                        'Smart tone mapping for different scenes',
                        widget.colorController.adaptiveHdrEnabled,
                        (value) {
                          setState(() {
                            widget.colorController.adaptiveHdrEnabled = value;
                          });
                        },
                      ),
                      
                      if (widget.hdrController.hdrEnabled) ...[
                        const SizedBox(height: 10),
                        _buildSliderSetting(
                          'HDR Frames',
                          '${widget.hdrController.maxHdrFrames}',
                          widget.hdrController.maxHdrFrames.toDouble(),
                          1.0,
                          5.0,
                          1.0,
                          (value) {
                            setState(() {
                              widget.hdrController.maxHdrFrames = value.round();
                            });
                          },
                        ),
                        
                        _buildSliderSetting(
                          'Exposure Range',
                          '±${widget.hdrController.bracketingRange.toStringAsFixed(1)} EV',
                          widget.hdrController.bracketingRange,
                          0.5,
                          4.0,
                          0.1,
                          (value) {
                            setState(() {
                              widget.hdrController.bracketingRange = value;
                            });
                          },
                        ),
                      ],
                      
                      const SizedBox(height: 20),
                      
                      // Tone Mapping Settings
                      _buildSectionHeader('Tone Mapping'),
                      _buildSliderSetting(
                        'Shadow Detail',
                        '${(widget.colorController.shadowDetail * 100).round()}%',
                        widget.colorController.shadowDetail,
                        0.0,
                        1.0,
                        0.05,
                        (value) {
                          setState(() {
                            widget.colorController.shadowDetail = value;
                          });
                        },
                      ),
                      
                      _buildSliderSetting(
                        'Highlight Recovery',
                        '${(widget.colorController.highlightRecovery * 100).round()}%',
                        widget.colorController.highlightRecovery,
                        0.0,
                        1.0,
                        0.05,
                        (value) {
                          setState(() {
                            widget.colorController.highlightRecovery = value;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Color Enhancement Settings
                      _buildSectionHeader('Color Enhancement'),
                      _buildSliderSetting(
                        'Saturation Boost',
                        '${(widget.colorController.saturationBoost * 100).round()}%',
                        widget.colorController.saturationBoost,
                        0.5,
                        2.0,
                        0.05,
                        (value) {
                          setState(() {
                            widget.colorController.saturationBoost = value;
                          });
                        },
                      ),
                      
                      _buildSliderSetting(
                        'Noise Reduction',
                        '${(widget.colorController.noiseReduction * 100).round()}%',
                        widget.colorController.noiseReduction,
                        0.0,
                        1.0,
                        0.05,
                        (value) {
                          setState(() {
                            widget.colorController.noiseReduction = value;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Preset buttons
                      _buildSectionHeader('Presets'),
                      _buildPresetButtons(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildToggleSetting(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue,
            thumbColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting(
    String title,
    String valueText,
    double value,
    double min,
    double max,
    double step,
    ValueChanged<double> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                valueText,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.blue,
              inactiveTrackColor: Colors.white.withOpacity(0.2),
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              trackHeight: 2,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: ((max - min) / step).round(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildPresetButton(
                'Natural',
                'iOS 18 Default',
                () => _applyNaturalPreset(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPresetButton(
                'Vivid',
                'Enhanced Colors',
                () => _applyVividPreset(),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: _buildPresetButton(
                'Portrait',
                'Skin Tone Focus',
                () => _applyPortraitPreset(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPresetButton(
                'Landscape',
                'Nature Colors',
                () => _applyLandscapePreset(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetButton(String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyNaturalPreset() {
    setState(() {
      // iOS 18 default settings
      widget.colorController.hdrEnabled = true;
      widget.colorController.displayP3Enabled = true;
      widget.colorController.adaptiveHdrEnabled = true;
      widget.colorController.saturationBoost = 1.15;
      widget.colorController.shadowDetail = 0.3;
      widget.colorController.highlightRecovery = 0.4;
      widget.colorController.noiseReduction = 0.2;
      
      widget.hdrController.hdrEnabled = true;
      widget.hdrController.maxHdrFrames = 3;
      widget.hdrController.bracketingRange = 2.0;
    });
  }

  void _applyVividPreset() {
    setState(() {
      // Enhanced color settings
      widget.colorController.hdrEnabled = true;
      widget.colorController.displayP3Enabled = true;
      widget.colorController.adaptiveHdrEnabled = true;
      widget.colorController.saturationBoost = 1.4;
      widget.colorController.shadowDetail = 0.4;
      widget.colorController.highlightRecovery = 0.5;
      widget.colorController.noiseReduction = 0.15;
      
      widget.hdrController.hdrEnabled = true;
      widget.hdrController.maxHdrFrames = 3;
      widget.hdrController.bracketingRange = 2.5;
    });
  }

  void _applyPortraitPreset() {
    setState(() {
      // Settings optimized for skin tones
      widget.colorController.hdrEnabled = true;
      widget.colorController.displayP3Enabled = true;
      widget.colorController.adaptiveHdrEnabled = true;
      widget.colorController.saturationBoost = 1.05;
      widget.colorController.shadowDetail = 0.5;
      widget.colorController.highlightRecovery = 0.3;
      widget.colorController.noiseReduction = 0.3;
      
      widget.hdrController.hdrEnabled = true;
      widget.hdrController.maxHdrFrames = 3;
      widget.hdrController.bracketingRange = 1.5;
    });
  }

  void _applyLandscapePreset() {
    setState(() {
      // Settings optimized for nature photography
      widget.colorController.hdrEnabled = true;
      widget.colorController.displayP3Enabled = true;
      widget.colorController.adaptiveHdrEnabled = true;
      widget.colorController.saturationBoost = 1.3;
      widget.colorController.shadowDetail = 0.2;
      widget.colorController.highlightRecovery = 0.6;
      widget.colorController.noiseReduction = 0.1;
      
      widget.hdrController.hdrEnabled = true;
      widget.hdrController.maxHdrFrames = 5;
      widget.hdrController.bracketingRange = 3.0;
    });
  }
}