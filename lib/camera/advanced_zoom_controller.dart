
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import '../ai/super_resolution_service.dart';

/// Advanced zoom controller that implements multiple zoom enhancement methods
/// Supports optical zoom, high-resolution crop, and AI super resolution
class AdvancedZoomController {
  // Zoom method preferences - can be configured by user
  bool opticalZoomEnabled = true;
  bool highResolutionCropEnabled = true;
  bool aiSuperResolutionEnabled = false; // Disabled by default due to performance

  
  // Device capabilities
  bool hasTelephotos = false;
  bool hasPeriScope = false;
  List<CameraDescription> availableCameras = [];
  CameraDescription? currentCamera;
  CameraController? _cameraController;
  
  // Zoom state
  double currentZoomLevel = 1.0;
  double maxOpticalZoom = 1.0;
  double maxDigitalZoom = 10.0;
  double maxSensorResolutionMP = 12.0; // Will be detected dynamically
  

  
  /// Initialize the advanced zoom controller
  /// Detects available cameras and their capabilities
  Future<void> initialize(List<CameraDescription> cameras) async {
    availableCameras = cameras;
    await _detectCameraCapabilities();
    await _detectSensorCapabilities();
  }
  
  /// Detect camera capabilities including telephoto and periscope lenses
  Future<void> _detectCameraCapabilities() async {
    try {
      // Check for telephoto cameras (usually 2x, 3x, 5x optical zoom)
      for (var camera in availableCameras) {
        // Camera naming patterns that indicate telephoto capability
        final cameraName = camera.name.toLowerCase();
        if (cameraName.contains('telephoto') || 
            cameraName.contains('tele') ||
            cameraName.contains('zoom') ||
            cameraName.contains('periscope')) {
          
          if (cameraName.contains('periscope')) {
            hasPeriScope = true;
            maxOpticalZoom = 10.0; // Periscope cameras typically offer 10x
          } else {
            hasTelephotos = true;
            // Most telephoto cameras offer 2x-5x optical zoom
            maxOpticalZoom = cameraName.contains('5x') ? 5.0 : 
                           cameraName.contains('3x') ? 3.0 : 2.0;
          }
        }
      }
      
      if (kDebugMode) {
        print('📷 Camera Capabilities Detected:');
        print('   Telephoto available: $hasTelephotos');
        print('   Periscope available: $hasPeriScope');
        print('   Max optical zoom: ${maxOpticalZoom}x');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error detecting camera capabilities: $e');
      }
    }
  }
  
  /// Detect sensor resolution capabilities for high-res crop method
  Future<void> _detectSensorCapabilities() async {
    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        // Get maximum resolution from camera controller
        final resolutions = _cameraController!.value.previewSize;
        if (resolutions != null) {
          double megapixels = (resolutions.width * resolutions.height) / 1000000;
          maxSensorResolutionMP = megapixels;
          
          if (kDebugMode) {
            print('📊 Sensor Capabilities:');
            print('   Max resolution: ${resolutions.width}x${resolutions.height}');
            print('   Estimated MP: ${maxSensorResolutionMP.toStringAsFixed(1)}MP');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error detecting sensor capabilities: $e');
      }
    }
  }
  
  /// Set the current camera controller
  Future<void> setCameraController(CameraController controller) async {
    _cameraController = controller;
    await _detectSensorCapabilities();
  }
  
  /// Get the optimal camera for the requested zoom level
  /// Returns the best camera (wide, telephoto, or periscope) based on zoom level
  CameraDescription? getOptimalCameraForZoom(double targetZoom) {
    if (!opticalZoomEnabled) return currentCamera;
    
    // Use periscope camera for 7x+ zoom if available
    if (targetZoom >= 7.0 && hasPeriScope) {
      for (var camera in availableCameras) {
        if (camera.name.toLowerCase().contains('periscope')) {
          return camera;
        }
      }
    }
    
    // Use telephoto camera for 2x-6x zoom if available
    if (targetZoom >= 2.0 && hasTelephotos) {
      for (var camera in availableCameras) {
        final name = camera.name.toLowerCase();
        if (name.contains('telephoto') || name.contains('tele')) {
          return camera;
        }
      }
    }
    
    // Use main/wide camera for 1x-2x zoom
    return availableCameras.isNotEmpty ? availableCameras[0] : null;
  }
  
  /// Apply zoom using the best available method
  /// Combines optical zoom, digital zoom, and enhancement techniques
  Future<void> setZoomLevel(double targetZoom) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    currentZoomLevel = targetZoom.clamp(1.0, maxDigitalZoom);
    
    try {
      // Method 1: Optical Zoom (preferred for quality)
      if (opticalZoomEnabled && targetZoom <= maxOpticalZoom) {
        await _applyOpticalZoom(targetZoom);
        if (kDebugMode) {
          print('🔍 Applied optical zoom: ${targetZoom}x');
        }
        return;
      }
      
      // Method 2: Hybrid zoom (optical + digital)
      if (opticalZoomEnabled && maxOpticalZoom > 1.0) {
        double opticalPortion = maxOpticalZoom;
        double digitalPortion = targetZoom / maxOpticalZoom;
        
        await _applyOpticalZoom(opticalPortion);
        await _applyDigitalZoom(digitalPortion);
        
        if (kDebugMode) {
          print('🔍 Applied hybrid zoom: ${opticalPortion}x optical + ${digitalPortion}x digital');
        }
        return;
      }
      
      // Method 3: Pure digital zoom with enhancements
      await _applyDigitalZoom(targetZoom);
      if (kDebugMode) {
        print('🔍 Applied digital zoom: ${targetZoom}x');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error applying zoom: $e');
      }
    }
  }
  
  /// Apply optical zoom using camera hardware
  Future<void> _applyOpticalZoom(double zoomLevel) async {
    if (_cameraController == null) return;
    
    try {
      // Use Camera API zoom controls
      await _cameraController!.setZoomLevel(zoomLevel);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Optical zoom failed, falling back to digital: $e');
      }
      await _applyDigitalZoom(zoomLevel);
    }
  }
  
  /// Apply digital zoom with camera controller
  Future<void> _applyDigitalZoom(double zoomLevel) async {
    if (_cameraController == null) return;
    
    try {
      await _cameraController!.setZoomLevel(zoomLevel);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Digital zoom failed: $e');
      }
    }
  }
  
  /// Capture high-resolution image and crop for zoom effect
  /// Method 2: High-resolution capture and crop
  Future<Uint8List?> captureHighResolutionZoomedImage(double zoomLevel) async {
    if (_cameraController == null || !highResolutionCropEnabled) return null;
    
    try {
      if (kDebugMode) {
        print('📸 Capturing high-resolution image for crop zoom...');
      }
      
      // Capture at maximum resolution
      final XFile imageFile = await _cameraController!.takePicture();
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      // Decode and crop the image
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return null;
      
      // Calculate crop area for zoom effect
      double cropFactor = 1.0 / zoomLevel;
      int cropWidth = (originalImage.width * cropFactor).round();
      int cropHeight = (originalImage.height * cropFactor).round();
      
      // Center the crop
      int cropX = ((originalImage.width - cropWidth) / 2).round();
      int cropY = ((originalImage.height - cropHeight) / 2).round();
      
      // Crop the image
      img.Image croppedImage = img.copyCrop(
        originalImage,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );
      
      // Resize back to original dimensions if needed
      img.Image finalImage = img.copyResize(
        croppedImage,
        width: originalImage.width,
        height: originalImage.height,
        interpolation: img.Interpolation.cubic,
      );
      
      if (kDebugMode) {
        print('✅ High-res crop completed: ${zoomLevel}x zoom');
      }
      
      return Uint8List.fromList(img.encodeJpg(finalImage, quality: 95));
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ High-resolution crop failed: $e');
      }
      return null;
    }
  }
  

  

  

  
  /// Capture image with all enhancement methods applied
  /// Orchestrates all zoom enhancement techniques
  Future<Uint8List?> captureEnhancedZoomedImage() async {
    if (_cameraController == null) return null;
    
    try {
      Uint8List? finalImage;
      
      // Method 2: High-resolution crop
      if (finalImage == null && highResolutionCropEnabled) {
        finalImage = await captureHighResolutionZoomedImage(currentZoomLevel);
      }
      
      // Fallback: Regular capture
      if (finalImage == null) {
        final XFile imageFile = await _cameraController!.takePicture();
        finalImage = await imageFile.readAsBytes();
      }
      
      // Method 3: AI Super Resolution (optional enhancement)
      if (finalImage != null && aiSuperResolutionEnabled) {
        final superResService = SuperResolutionService();
        final enhanced = await superResService.enhanceImage(finalImage);
        if (enhanced != null) finalImage = enhanced;
        superResService.dispose();
      }
      
      if (kDebugMode) {
        print('✅ Enhanced zoom image captured at ${currentZoomLevel}x');
      }
      
      return finalImage;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Enhanced capture failed: $e');
      }
      return null;
    }
  }
  
  /// Get user-friendly zoom method description
  String getCurrentZoomMethodDescription() {
    if (currentZoomLevel <= maxOpticalZoom && opticalZoomEnabled) {
      return 'Optical Zoom (${currentZoomLevel.toStringAsFixed(1)}x)';
    } else if (currentZoomLevel > maxOpticalZoom && opticalZoomEnabled) {
      return 'Hybrid Zoom (${maxOpticalZoom}x optical + digital)';
    } else if (highResolutionCropEnabled) {
      return 'High-res Crop (${currentZoomLevel.toStringAsFixed(1)}x)';
    } else {
      return 'Digital Zoom (${currentZoomLevel.toStringAsFixed(1)}x)';
    }
  }
  
  /// Get capabilities summary for UI display
  Map<String, dynamic> getCapabilitiesSummary() {
    return {
      'hasOpticalZoom': maxOpticalZoom > 1.0,
      'maxOpticalZoom': maxOpticalZoom,
      'hasTelephotos': hasTelephotos,
      'hasPeriScope': hasPeriScope,
      'maxDigitalZoom': maxDigitalZoom,
      'sensorResolutionMP': maxSensorResolutionMP,
      'enhancementsEnabled': {
        'optical': opticalZoomEnabled,
        'highResCrop': highResolutionCropEnabled,
        'aiSuperRes': aiSuperResolutionEnabled,

      }
    };
  }
  
  /// Cleanup resources
  void dispose() {
    _cameraController = null;
  }
}