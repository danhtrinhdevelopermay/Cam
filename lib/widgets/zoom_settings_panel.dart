import 'package:flutter/material.dart';
import 'dart:ui';
import '../camera/advanced_zoom_controller.dart';

/// Settings panel for configuring zoom enhancement methods
/// Allows users to enable/disable individual zoom techniques
class ZoomSettingsPanel extends StatefulWidget {
  final AdvancedZoomController zoomController;
  final VoidCallback onClose;

  const ZoomSettingsPanel({
    super.key,
    required this.zoomController,
    required this.onClose,
  });

  @override
  State<ZoomSettingsPanel> createState() => _ZoomSettingsPanelState();
}

class _ZoomSettingsPanelState extends State<ZoomSettingsPanel> {
  @override
  Widget build(BuildContext context) {
    final capabilities = widget.zoomController.getCapabilitiesSummary();
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.zoom_in,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '10x Zoom Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Device Capabilities
                        _buildCapabilitiesSection(capabilities),
                        
                        const SizedBox(height: 24),
                        
                        // Enhancement Methods
                        _buildEnhancementMethodsSection(),
                        
                        const SizedBox(height: 24),
                        
                        // Performance Settings
                        _buildPerformanceSection(),
                        
                        const SizedBox(height: 100), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCapabilitiesSection(Map<String, dynamic> capabilities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Device Capabilities',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildCapabilityItem(
                'Optical Zoom',
                capabilities['hasOpticalZoom']
                    ? '${capabilities['maxOpticalZoom']}x available'
                    : 'Not available',
                capabilities['hasOpticalZoom'],
              ),
              _buildCapabilityItem(
                'Telephoto Lens',
                capabilities['hasTelephotos'] ? 'Available' : 'Not detected',
                capabilities['hasTelephotos'],
              ),
              _buildCapabilityItem(
                'Periscope Lens',
                capabilities['hasPeriScope'] ? 'Available' : 'Not detected',
                capabilities['hasPeriScope'],
              ),
              _buildCapabilityItem(
                'Sensor Resolution',
                '${capabilities['sensorResolutionMP'].toStringAsFixed(1)}MP',
                capabilities['sensorResolutionMP'] > 20,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCapabilityItem(String title, String value, bool isGood, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Icon(
            isGood ? Icons.check_circle : Icons.info,
            color: isGood ? Colors.green : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancementMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enhancement Methods',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        _buildMethodToggle(
          'Optical Zoom',
          'Use telephoto/periscope cameras when available',
          Icons.camera_alt,
          widget.zoomController.opticalZoomEnabled,
          (value) => setState(() => widget.zoomController.opticalZoomEnabled = value),
          true,
        ),
        
        _buildMethodToggle(
          'High-Resolution Crop',
          'Crop from maximum sensor resolution',
          Icons.crop,
          widget.zoomController.highResolutionCropEnabled,
          (value) => setState(() => widget.zoomController.highResolutionCropEnabled = value),
          true,
        ),
        

        _buildMethodToggle(
          'AI Super Resolution',
          'AI-powered image enhancement (requires internet)',
          Icons.auto_awesome,
          widget.zoomController.aiSuperResolutionEnabled,
          (value) => setState(() => widget.zoomController.aiSuperResolutionEnabled = value),
          false,
        ),
      ],
    );
  }

  Widget _buildMethodToggle(
    String title,
    String description,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    bool recommended,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value 
            ? Colors.yellow.withOpacity(0.3)
            : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: value 
                ? Colors.yellow.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: value ? Colors.yellow : Colors.white.withOpacity(0.7),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (recommended)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'RECOMMENDED',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
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

  Widget _buildPerformanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Tips',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb,
                    color: Colors.blue,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'For Best Results',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '• Hold device steady during high zoom capture\n'
                '• AI enhancement works best with internet connection\n'
                '• Higher zoom levels take longer to process',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}