import 'package:flutter/material.dart';
import '../video/video_recording_controller.dart';
import '../widgets/blur_overlay.dart';

class VideoSettingsPanel extends StatefulWidget {
  final VideoRecordingController videoController;
  final Function(VideoRecordingSettings) onSettingsChanged;
  final VoidCallback onClose;

  const VideoSettingsPanel({
    super.key,
    required this.videoController,
    required this.onSettingsChanged,
    required this.onClose,
  });

  @override
  State<VideoSettingsPanel> createState() => _VideoSettingsPanelState();
}

class _VideoSettingsPanelState extends State<VideoSettingsPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  VideoResolution _selectedResolution = VideoResolution.hd720p;
  VideoFrameRate _selectedFrameRate = VideoFrameRate.fps30;
  bool _enableAudio = true;

  @override
  void initState() {
    super.initState();
    
    final currentSettings = widget.videoController.currentSettings;
    _selectedResolution = currentSettings.resolution;
    _selectedFrameRate = currentSettings.frameRate;
    _enableAudio = currentSettings.enableAudio;
    
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

  void _applySettings() {
    final newSettings = VideoRecordingSettings(
      resolution: _selectedResolution,
      frameRate: _selectedFrameRate,
      enableAudio: _enableAudio,
    );
    
    widget.onSettingsChanged(newSettings);
    _closePanel();
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
            Opacity(
              opacity: _fadeAnimation.value * 0.7,
              child: Container(
                color: Colors.black,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            
            // Settings panel
            Positioned(
              right: 16 + (200 * _slideAnimation.value),
              top: 100,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: iOS18GlassEffect(
                  borderRadius: BorderRadius.circular(24),
                  padding: const EdgeInsets.all(24),
                  blur: 20.0,
                  opacity: 0.85,
                  child: SizedBox(
                    width: 280,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Video Settings',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            GestureDetector(
                              onTap: _closePanel,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Resolution Selection
                        _buildSettingSection(
                          title: 'Resolution',
                          child: Column(
                            children: VideoResolution.values.map((resolution) {
                              return _buildSettingOption(
                                title: resolution.label,
                                subtitle: '${resolution.size.width.toInt()}×${resolution.size.height.toInt()}',
                                isSelected: _selectedResolution == resolution,
                                onTap: () {
                                  setState(() {
                                    _selectedResolution = resolution;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Frame Rate Selection
                        _buildSettingSection(
                          title: 'Frame Rate',
                          child: Column(
                            children: VideoFrameRate.values.map((frameRate) {
                              final bool is60fps = frameRate == VideoFrameRate.fps60;
                              return _buildSettingOption(
                                title: frameRate.label,
                                subtitle: is60fps ? 'AI Enhanced' : 'Standard',
                                isSelected: _selectedFrameRate == frameRate,
                                onTap: () {
                                  setState(() {
                                    _selectedFrameRate = frameRate;
                                  });
                                },
                                trailing: is60fps ? const Icon(
                                  Icons.auto_fix_high,
                                  color: Colors.amber,
                                  size: 16,
                                ) : null,
                              );
                            }).toList(),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Audio Toggle
                        _buildSettingSection(
                          title: 'Audio',
                          child: _buildSwitchOption(
                            title: 'Record Audio',
                            subtitle: 'Include audio in video recording',
                            value: _enableAudio,
                            onChanged: (value) {
                              setState(() {
                                _enableAudio = value;
                              });
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // AI Enhancement Info
                        if (_selectedFrameRate == VideoFrameRate.fps60)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.amber.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '60fps will use AI frame interpolation on devices that don\'t support native 60fps recording',
                                    style: TextStyle(
                                      color: Colors.amber.shade200,
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 20),
                        
                        // Apply Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _applySettings,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Apply Settings',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildSettingOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.blue.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: Colors.blue.withOpacity(0.5))
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
            if (trailing != null) trailing,
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.blue,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchOption({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
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
                    fontWeight: FontWeight.w400,
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
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }
}