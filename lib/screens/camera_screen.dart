
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';

import '../widgets/blur_overlay.dart';
import '../widgets/mode_selector.dart';
import '../widgets/aspect_ratio_selector.dart';
import '../widgets/advanced_zoom_controls.dart';
import '../widgets/color_settings_panel.dart';
import '../widgets/video_settings_panel.dart';
import '../camera/advanced_zoom_controller.dart';
import '../camera/color_processing_controller.dart';
import '../camera/hdr_capture_controller.dart';
import '../video/video_recording_controller.dart';


class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  
  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  bool _isFlashOn = false;
  int _selectedCameraIndex = 0;
  String _currentMode = 'photo';
  double _zoomLevel = 1.0;

  CameraAspectRatio _selectedAspectRatio = CameraAspectRatio.full;
  
  // Advanced zoom controller for 10x zoom capabilities
  late AdvancedZoomController _advancedZoomController;
  
  // iOS 18-style color processing controllers
  late ColorProcessingController _colorProcessingController;
  late HdrCaptureController _hdrCaptureController;
  
  // Video recording controller
  late VideoRecordingController _videoRecordingController;
  
  // UI state
  bool _showColorSettings = false;
  bool _showVideoSettings = false;
  String? _currentVideoPath;
  
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize controllers first
    _advancedZoomController = AdvancedZoomController();
    _colorProcessingController = ColorProcessingController();
    _hdrCaptureController = HdrCaptureController();
    _videoRecordingController = VideoRecordingController();
    
    // Setup animations immediately
    _setupAnimations();
    
    // Start camera initialization immediately
    _initializeCameraFast();
    
    // Run other tasks in parallel
    Future.wait([
      _requestPermissions(),
      _initializeAdvancedZoom(),
    ]);
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  Future<void> _requestPermissions() async {
    // Request permissions in parallel for faster startup
    Future.wait([
      Permission.camera.request(),
      Permission.microphone.request(),
      Permission.storage.request(),
    ]);
  }

  Future<void> _initializeCameraFast() async {
    if (widget.cameras.isEmpty) return;

    // Use medium resolution to avoid aspect ratio issues
    _cameraController = CameraController(
      widget.cameras[_selectedCameraIndex],
      ResolutionPreset.medium, // Medium for better aspect ratio compatibility
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      // Initialize camera with minimal blocking operations
      await _cameraController!.initialize();
      
      setState(() {
        _isCameraInitialized = true;
      });
      
      // Configure advanced features after camera is visible
      _configureAdvancedFeaturesAsync();
      
      // Initialize video recording controller with camera
      _videoRecordingController.setCameraController(_cameraController!);
      
    } catch (e) {
      print('Camera initialization error: $e');
      // Fallback with lower resolution for compatibility
      _initializeCameraFallback();
    }
  }

  Future<void> _configureAdvancedFeaturesAsync() async {
    if (_cameraController == null) return;
    
    try {
      // Configure advanced features without blocking UI
      await Future.wait([
        _advancedZoomController.setCameraController(_cameraController!),
        _colorProcessingController.configureCameraForAdvancedColor(_cameraController!),
      ]);
      
      // Update camera reference
      _advancedZoomController.currentCamera = widget.cameras[_selectedCameraIndex];
      
    } catch (e) {
      print('Advanced features configuration error: $e');
    }
  }

  Future<void> _initializeCameraFallback() async {
    if (widget.cameras.isEmpty) return;

    _cameraController = CameraController(
      widget.cameras[_selectedCameraIndex],
      ResolutionPreset.medium, // Lower resolution for compatibility
      enableAudio: false, // Disable audio for faster startup
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
      _configureAdvancedFeaturesAsync();
    } catch (e) {
      print('Camera fallback initialization error: $e');
    }
  }

  // Keep original method for app lifecycle management
  Future<void> _initializeCamera() async {
    await _initializeCameraFast();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _animationController.dispose();
    _advancedZoomController.dispose();
    _videoRecordingController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _cameraController == null) return;

    try {
      // Capture HDR image with advanced color processing
      final hdrResult = await _hdrCaptureController.captureHdrImage(_cameraController!);
      final imageData = hdrResult['image'] as Uint8List;
      final isHdr = hdrResult['isHdr'] as bool;
      
      // Apply iOS 18-style color processing
      final processedImageData = await _colorProcessingController.processImageWithAdvancedColor(imageData);
      
      // Save processed image to gallery
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/ios18_photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(processedImageData);
      
      await ImageGallerySaver.saveFile(tempFile.path);
      
      // Clean up temp file
      await tempFile.delete();
      
      // Show success feedback with processing info
      if (mounted) {
        final processingInfo = isHdr ? 'HDR + P3' : 'P3 Enhanced';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo saved (${_selectedAspectRatio.label}, $processingInfo)'),
            backgroundColor: Colors.green.withOpacity(0.8),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error taking picture: $e');
      // Fallback to standard capture
      try {
        final XFile image = await _cameraController!.takePicture();
        await ImageGallerySaver.saveFile(image.path);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Photo saved (Standard mode) - ${_selectedAspectRatio.label}'),
              backgroundColor: Colors.orange.withOpacity(0.8),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (fallbackError) {
        print('Fallback capture also failed: $fallbackError');
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;

    try {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      print('Error toggling flash: $e');
    }
  }



  Future<void> _initializeAdvancedZoom() async {
    await _advancedZoomController.initialize(widget.cameras);
    if (_cameraController != null) {
      _advancedZoomController.setCameraController(_cameraController!);
    }
  }

  void _onZoomChanged(double zoom) async {
    if (_cameraController != null) {
      // Use advanced zoom controller for enhanced zoom capabilities
      await _advancedZoomController.setZoomLevel(zoom);
      setState(() {
        _zoomLevel = zoom;
      });
    }
  }

  Future<void> _captureEnhancedPhoto() async {
    if (!_isCameraInitialized || _cameraController == null) return;

    try {
      // Use advanced zoom controller for enhanced capture
      final imageData = await _advancedZoomController.captureEnhancedZoomedImage();
      
      if (imageData != null) {
        // Apply iOS 18-style color processing to enhanced image
        final processedImageData = await _colorProcessingController.processImageWithAdvancedColor(imageData);
        
        // Save to gallery using temporary file
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/enhanced_ios18_photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(processedImageData);
        
        await ImageGallerySaver.saveFile(tempFile.path);
        
        // Clean up temp file
        await tempFile.delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Enhanced photo saved (${_selectedAspectRatio.label}, ${_advancedZoomController.getCurrentZoomMethodDescription()}, iOS 18 Colors)'),
              backgroundColor: Colors.green.withOpacity(0.8),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('Enhanced capture failed');
      }
    } catch (e) {
      // Fallback to regular capture with color processing
      await _takePicture();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enhanced zoom failed, used standard capture with iOS 18 colors'),
            backgroundColor: Colors.orange.withOpacity(0.8),
          ),
        );
      }
    }
  }

  // Video Recording Methods
  Future<void> _toggleVideoRecording() async {
    if (!_isCameraInitialized || _cameraController == null) return;
    
    if (_videoRecordingController.isRecording) {
      // Stop recording
      final String? videoPath = await _videoRecordingController.stopVideoRecording();
      
      if (videoPath != null) {
        // Save to gallery
        await ImageGallerySaver.saveFile(videoPath);
        
        setState(() {
          _currentVideoPath = null;
        });
        
        if (mounted) {
          final settings = _videoRecordingController.currentSettings;
          final processingNote = settings.frameRate == VideoFrameRate.fps60 ? 
              ' (AI Enhanced 60fps)' : '';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Video saved: ${settings.resolution.label}@${settings.frameRate.label}$processingNote'),
              backgroundColor: Colors.green.withOpacity(0.8),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      // Start recording
      final String? videoPath = await _videoRecordingController.startVideoRecording();
      
      if (videoPath != null) {
        setState(() {
          _currentVideoPath = videoPath;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_videoRecordingController.getRecordingStatusText()),
              backgroundColor: Colors.red.withOpacity(0.8),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  void _onVideoSettingsChanged(VideoRecordingSettings settings) {
    _videoRecordingController.updateVideoSettings(settings);
    setState(() {
      // Update UI if needed
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview - Full Screen with Proper Scaling
          if (_isCameraInitialized)
            Positioned.fill(
              child: OverflowBox(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width * _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
            )
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),

          // Aspect Ratio Overlay (separate from camera preview)
          if (_isCameraInitialized && _selectedAspectRatio != CameraAspectRatio.full)
            _buildAspectRatioOverlay(),



          // Top Controls - iOS 18 Style
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Flash Button - iOS 18 Style
                  iOS18CircularButton(
                    icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    onTap: _toggleFlash,
                    isActive: _isFlashOn,
                    size: 44,
                  ),

                  // Zoom Level Indicator - iOS 18 Style  
                  if (_isCameraInitialized)
                    iOS18GlassEffect(
                      borderRadius: BorderRadius.circular(20),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      blur: 15.0,
                      opacity: 0.4,
                      child: Text(
                        '${_zoomLevel.toStringAsFixed(1)}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                  // Video Settings Button - iOS 18 Style (show only in video mode)
                  if (_currentMode == 'video')
                    iOS18CircularButton(
                      icon: Icons.video_settings,
                      onTap: () {
                        setState(() {
                          _showVideoSettings = !_showVideoSettings;
                        });
                      },
                      isActive: _showVideoSettings,
                      size: 44,
                    )
                  else
                    // Color Settings Button - iOS 18 Style  
                    iOS18CircularButton(
                      icon: Icons.palette,
                      onTap: () {
                        setState(() {
                          _showColorSettings = !_showColorSettings;
                        });
                      },
                      isActive: _showColorSettings,
                      size: 44,
                    ),
                ],
              ),
            ),
          ),

          // Bottom Controls Panel - Reorganized for better UX
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: _buildBottomControlsPanel(),
            ),
          ),
          
          // Color Settings Panel
          if (_showColorSettings)
            ColorSettingsPanel(
              colorController: _colorProcessingController,
              hdrController: _hdrCaptureController,
              onClose: () {
                setState(() {
                  _showColorSettings = false;
                });
              },
            ),
          
          // Video Settings Panel
          if (_showVideoSettings)
            VideoSettingsPanel(
              videoController: _videoRecordingController,
              onSettingsChanged: _onVideoSettingsChanged,
              onClose: () {
                setState(() {
                  _showVideoSettings = false;
                });
              },
            ),
        ],
      ),
    );
  }

  /// Build aspect ratio overlay without affecting camera preview
  Widget _buildAspectRatioOverlay() {
    final screenSize = MediaQuery.of(context).size;
    final targetAspectRatio = _selectedAspectRatio.value;
    final screenAspectRatio = screenSize.width / screenSize.height;
    
    double overlayWidth = screenSize.width;
    double overlayHeight = screenSize.height;
    
    if (targetAspectRatio > screenAspectRatio) {
      overlayHeight = overlayWidth / targetAspectRatio;
    } else {
      overlayWidth = overlayHeight * targetAspectRatio;
    }

    final topBottomOverlay = (screenSize.height - overlayHeight) / 2;
    final leftRightOverlay = (screenSize.width - overlayWidth) / 2;

    return Stack(
      children: [
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

  /// Build organized bottom controls panel with iOS 18 glass morphism styling
  Widget _buildBottomControlsPanel() {
    return iOS18GlassEffect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      padding: const EdgeInsets.all(20),
      blur: 25.0,
      opacity: 0.35,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Aspect Ratio Selector (top level)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: AspectRatioSelector(
              selectedRatio: _selectedAspectRatio,
              onRatioChanged: (ratio) {
                setState(() {
                  _selectedAspectRatio = ratio;
                });
              },
            ),
          ),
          
          // Row 2: Mode Selector (middle level)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: ModeSelector(
              currentMode: _currentMode,
              onModeChanged: (mode) {
                setState(() {
                  _currentMode = mode;
                });
              },
            ),
          ),
          
          // Row 3: Main Controls (camera capture or video recording)
          if (_isCameraInitialized)
            _currentMode == 'video' ? _buildVideoRecordingControls() : AdvancedZoomControls(
              zoomController: _advancedZoomController,
              onZoomChanged: _onZoomChanged,
              onCapturePressed: _captureEnhancedPhoto,
            ),
          
          // Additional bottom spacing for iOS 18 look
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Build video recording controls with iOS 18 styling
  Widget _buildVideoRecordingControls() {
    final isRecording = _videoRecordingController.isRecording;
    final isProcessing = _videoRecordingController.isProcessing;
    final currentSettings = _videoRecordingController.currentSettings;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Video Settings Info Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam,
                color: isRecording ? Colors.red : Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                currentSettings.toString(),
                style: TextStyle(
                  color: isRecording ? Colors.red : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (currentSettings.frameRate == VideoFrameRate.fps60) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'AI',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Recording Controls Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Gallery/Preview Button
            GestureDetector(
              onTap: isRecording || isProcessing ? null : () {
                // Open gallery or show last video preview
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.photo_library,
                  color: isRecording || isProcessing 
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white,
                  size: 24,
                ),
              ),
            ),
            
            // Main Record Button
            GestureDetector(
              onTap: isProcessing ? null : _toggleVideoRecording,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isProcessing ? Colors.grey : (isRecording ? Colors.red : Colors.white),
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isProcessing)
                      const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isRecording ? Icons.stop : Icons.fiber_manual_record,
                          key: ValueKey(isRecording),
                          color: isRecording ? Colors.white : Colors.red,
                          size: isRecording ? 35 : 30,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Switch Camera Button
            GestureDetector(
              onTap: isRecording || isProcessing ? null : () {
                // Switch camera
                _switchCamera();
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.flip_camera_ios,
                  color: isRecording || isProcessing 
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
        
        // Processing Status
        if (isProcessing)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Processing video with AI frame interpolation...',
              style: TextStyle(
                color: Colors.amber.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        
        // Recording Status
        if (isRecording)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'REC',
                  style: TextStyle(
                    color: Colors.red.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _switchCamera() async {
    if (_cameraController == null || widget.cameras.length < 2) return;

    try {
      final newCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
      
      await _cameraController?.dispose();
      
      _cameraController = CameraController(
        widget.cameras[newCameraIndex],
        ResolutionPreset.medium,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await _cameraController!.initialize();
      
      setState(() {
        _selectedCameraIndex = newCameraIndex;
        _isCameraInitialized = true;
      });
      
      // Update video recording controller with new camera
      _videoRecordingController.setCameraController(_cameraController!);
      
    } catch (e) {
      print('Error switching camera: $e');
    }
  }


}