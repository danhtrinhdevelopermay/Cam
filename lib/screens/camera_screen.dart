
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../widgets/blur_overlay.dart';
import '../widgets/mode_selector.dart';
import '../widgets/aspect_ratio_selector.dart';
import '../widgets/advanced_zoom_controls.dart';
import '../camera/advanced_zoom_controller.dart';
import 'dart:ui';

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
  
  late AnimationController _animationController;
  late AnimationController _blurController;
  late Animation<double> _blurAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _advancedZoomController = AdvancedZoomController();
    _initializeCamera();
    _setupAnimations();
    _requestPermissions();
    _initializeAdvancedZoom();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _blurController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _blurAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _blurController,
      curve: Curves.easeOut,
    ));
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ].request();
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) return;

    _cameraController = CameraController(
      widget.cameras[_selectedCameraIndex],
      ResolutionPreset.max, // Use maximum resolution for high-res crop method
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController!.initialize();
      
      // Update advanced zoom controller with new camera
      _advancedZoomController.setCameraController(_cameraController!);
      _advancedZoomController.currentCamera = widget.cameras[_selectedCameraIndex];
      
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print('Camera initialization error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _animationController.dispose();
    _blurController.dispose();
    _advancedZoomController.dispose();
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
      // Trigger blur effect
      _blurController.forward().then((_) {
        _blurController.reverse();
      });

      final XFile image = await _cameraController!.takePicture();
      
      // Save to gallery
      await ImageGallerySaver.saveFile(image.path);
      
      // Show success feedback with aspect ratio info
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo saved to gallery (${_selectedAspectRatio.label})'),
            backgroundColor: Colors.green.withOpacity(0.8),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error taking picture: $e');
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

  Future<void> _switchCamera() async {
    if (widget.cameras.length < 2) return;

    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
      _isCameraInitialized = false;
    });

    await _cameraController?.dispose();
    await _initializeCamera();
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
      // Trigger blur animation
      _blurController.forward().then((_) {
        _blurController.reverse();
      });

      // Use advanced zoom controller for enhanced capture
      final imageData = await _advancedZoomController.captureEnhancedZoomedImage();
      
      if (imageData != null) {
        // Save to gallery using temporary file
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/enhanced_photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(imageData);
        
        await ImageGallerySaver.saveFile(tempFile.path);
        
        // Clean up temp file
        await tempFile.delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Enhanced photo saved (${_selectedAspectRatio.label}, ${_advancedZoomController.getCurrentZoomMethodDescription()})'),
              backgroundColor: Colors.green.withOpacity(0.8),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('Enhanced capture failed');
      }
    } catch (e) {
      // Fallback to regular capture
      await _takePicture();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fallback to regular capture: $e'),
            backgroundColor: Colors.orange.withOpacity(0.8),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview with Aspect Ratio Overlay
          if (_isCameraInitialized)
            AspectRatioOverlay(
              aspectRatio: _selectedAspectRatio,
              screenSize: MediaQuery.of(context).size,
              child: SizedBox.expand(
                child: AspectRatio(
                  aspectRatio: _cameraController!.value.aspectRatio,
                  child: CameraPreview(_cameraController!),
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

          // Blur Overlay Effect
          AnimatedBuilder(
            animation: _blurAnimation,
            builder: (context, child) {
              return BlurOverlay(
                sigmaX: _blurAnimation.value,
                sigmaY: _blurAnimation.value,
              );
            },
          ),

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

                  // Settings Button - iOS 18 Style
                  iOS18CircularButton(
                    icon: Icons.settings,
                    onTap: () {
                      // TODO: Open settings
                    },
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
        ],
      ),
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
          
          // Row 3: Advanced Zoom Controls (bottom level - main interaction)
          if (_isCameraInitialized)
            AdvancedZoomControls(
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
}