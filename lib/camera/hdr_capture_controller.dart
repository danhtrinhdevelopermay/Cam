
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'dart:math' as math;

/// HDR capture controller with gain map support
/// Implements iOS 18-style Adaptive HDR with multi-frame capture and tone mapping
class HdrCaptureController {
  // HDR capture settings
  bool _hdrEnabled = true;
  bool _gainMapEnabled = true;
  int _maxHdrFrames = 3;
  double _bracketingRange = 2.0; // EV range for bracketing
  
  // Capture state
  bool _isCapturingHdr = false;
  List<Uint8List> _capturedFrames = [];
  List<double> _frameExposures = [];
  
  // Auto exposure settings
  double _baseExposure = 0.0;
  double _optimalExposure = 0.0;
  
  /// Capture HDR image with multiple exposures
  Future<Map<String, dynamic>> captureHdrImage(CameraController controller) async {
    if (!_hdrEnabled || _isCapturingHdr) {
      // Fallback to standard capture
      final standardImage = await controller.takePicture();
      final imageData = await standardImage.readAsBytes();
      return {
        'image': imageData,
        'isHdr': false,
        'gainMap': null,
      };
    }
    
    try {
      _isCapturingHdr = true;
      _capturedFrames.clear();
      _frameExposures.clear();
      
      if (kDebugMode) {
        print('📸 Starting HDR capture with $_maxHdrFrames frames...');
      }
      
      // Get current exposure settings
      await _analyzeScene(controller);
      
      // Capture bracketed frames
      await _captureBracketedFrames(controller);
      
      // Process HDR image
      final hdrResult = await _processHdrFrames();
      
      if (kDebugMode) {
        print('✅ HDR capture completed successfully');
      }
      
      return hdrResult;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ HDR capture failed: $e');
      }
      
      // Fallback to standard capture
      final standardImage = await controller.takePicture();
      final imageData = await standardImage.readAsBytes();
      return {
        'image': imageData,
        'isHdr': false,
        'gainMap': null,
        'error': e.toString(),
      };
      
    } finally {
      _isCapturingHdr = false;
    }
  }
  
  /// Analyze scene to determine optimal HDR settings
  Future<void> _analyzeScene(CameraController controller) async {
    try {
      // For simulation, we'll use basic exposure analysis
      // In a real implementation, this would analyze histogram and scene characteristics
      _baseExposure = 0.0; // Current exposure
      _optimalExposure = _baseExposure;
      
      if (kDebugMode) {
        print('🔍 Scene analysis:');
        print('   Base exposure: $_baseExposure EV');
        print('   Optimal exposure: $_optimalExposure EV');
        print('   Bracketing range: ±$_bracketingRange EV');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Scene analysis failed: $e');
      }
    }
  }
  
  /// Capture multiple frames with different exposures
  Future<void> _captureBracketedFrames(CameraController controller) async {
    try {
      // Calculate exposure brackets
      final exposures = _calculateExposureBrackets();
      
      for (int i = 0; i < exposures.length; i++) {
        final targetExposure = exposures[i];
        
        if (kDebugMode) {
          print('📷 Capturing frame ${i + 1}/$_maxHdrFrames at ${targetExposure.toStringAsFixed(1)} EV');
        }
        
        // Set exposure for this frame
        await _setExposureForFrame(controller, targetExposure);
        
        // Small delay for exposure to stabilize
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Capture frame
        final image = await controller.takePicture();
        final imageData = await image.readAsBytes();
        
        _capturedFrames.add(imageData);
        _frameExposures.add(targetExposure);
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Bracket capture failed: $e');
      }
      rethrow;
    }
  }
  
  /// Calculate exposure brackets for HDR capture
  List<double> _calculateExposureBrackets() {
    final brackets = <double>[];
    
    if (_maxHdrFrames == 1) {
      brackets.add(_baseExposure);
    } else if (_maxHdrFrames == 3) {
      // Standard 3-frame HDR: underexposed, normal, overexposed
      brackets.add(_baseExposure - _bracketingRange); // Shadows
      brackets.add(_baseExposure);                    // Mid-tones
      brackets.add(_baseExposure + _bracketingRange); // Highlights
    } else {
      // More frames for higher quality HDR
      final step = (_bracketingRange * 2) / (_maxHdrFrames - 1);
      for (int i = 0; i < _maxHdrFrames; i++) {
        brackets.add(_baseExposure - _bracketingRange + (i * step));
      }
    }
    
    return brackets;
  }
  
  /// Set camera exposure for specific frame
  Future<void> _setExposureForFrame(CameraController controller, double targetExposure) async {
    try {
      // Note: Real implementation would use platform-specific exposure control
      // For simulation, we'll use the available camera controls
      
      // Convert EV to exposure offset (simplified)
      final exposureOffset = targetExposure / 3.0; // Rough conversion
      final clampedOffset = math.max(-1.0, math.min(1.0, exposureOffset));
      
      await controller.setExposureOffset(clampedOffset);
      
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not set exposure offset: $e');
      }
      // Continue with current exposure
    }
  }
  
  /// Process captured HDR frames into final image with gain map
  Future<Map<String, dynamic>> _processHdrFrames() async {
    if (_capturedFrames.isEmpty) {
      throw Exception('No frames captured for HDR processing');
    }
    
    try {
      // Decode all frames
      final decodedFrames = <img.Image>[];
      for (final frameData in _capturedFrames) {
        final image = img.decodeImage(frameData);
        if (image != null) {
          decodedFrames.add(image);
        }
      }
      
      if (decodedFrames.isEmpty) {
        throw Exception('Failed to decode HDR frames');
      }
      
      // Align frames (simplified - assumes camera was stable)
      final alignedFrames = await _alignFrames(decodedFrames);
      
      // Merge frames into HDR image
      final hdrImage = await _mergeHdrFrames(alignedFrames);
      
      // Generate gain map if enabled
      Uint8List? gainMap;
      if (_gainMapEnabled) {
        gainMap = await _generateGainMap(hdrImage, alignedFrames);
      }
      
      // Tone map for standard display
      final toneMappedImage = await _toneMapHdrImage(hdrImage);
      
      // Encode final image
      final finalImageData = img.encodeJpg(toneMappedImage, quality: 95);
      
      return {
        'image': Uint8List.fromList(finalImageData),
        'isHdr': true,
        'gainMap': gainMap,
        'frameCount': _capturedFrames.length,
        'exposures': List.from(_frameExposures),
      };
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ HDR processing failed: $e');
      }
      rethrow;
    }
  }
  
  /// Align multiple frames (simplified implementation)
  Future<List<img.Image>> _alignFrames(List<img.Image> frames) async {
    // In a real implementation, this would use feature detection and matching
    // For simulation, we assume frames are already aligned
    return frames;
  }
  
  /// Merge HDR frames using exposure fusion
  Future<img.Image> _mergeHdrFrames(List<img.Image> frames) async {
    if (frames.length == 1) {
      return frames[0];
    }
    
    final width = frames[0].width;
    final height = frames[0].height;
    final mergedImage = img.Image(width: width, height: height);
    
    // Exposure fusion algorithm
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double totalR = 0, totalG = 0, totalB = 0;
        double totalWeight = 0;
        
        for (int i = 0; i < frames.length; i++) {
          final pixel = frames[i].getPixel(x, y);
          final exposure = _frameExposures[i];
          
          // Calculate weight based on pixel brightness and exposure
          final weight = _calculatePixelWeight(pixel, exposure);
          
          totalR += pixel.r * weight;
          totalG += pixel.g * weight;
          totalB += pixel.b * weight;
          totalWeight += weight;
        }
        
        if (totalWeight > 0) {
          mergedImage.setPixel(x, y, img.ColorRgb8(
            (totalR / totalWeight).round().toInt().clamp(0, 255),
            (totalG / totalWeight).round().toInt().clamp(0, 255),
            (totalB / totalWeight).round().toInt().clamp(0, 255),
          ));
        }
      }
    }
    
    return mergedImage;
  }
  
  /// Calculate pixel weight for exposure fusion
  double _calculatePixelWeight(img.Color pixel, double exposure) {
    // Calculate luminance
    final luminance = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b) / 255.0;
    
    // Well-exposedness weight (favor mid-tones)
    final wellExposed = math.exp(-12.5 * math.pow(luminance - 0.5, 2));
    
    // Saturation weight
    final maxChannel = math.max(math.max(pixel.r, pixel.g), pixel.b) / 255.0;
    final minChannel = math.min(math.min(pixel.r, pixel.g), pixel.b) / 255.0;
    final saturation = maxChannel - minChannel;
    final saturationWeight = math.pow(saturation, 0.2);
    
    // Contrast weight (simplified)
    final contrast = 1.0; // Would require local contrast calculation
    
    return wellExposed * saturationWeight * contrast;
  }
  
  /// Generate gain map for HDR display compatibility
  Future<Uint8List> _generateGainMap(img.Image hdrImage, List<img.Image> frames) async {
    try {
      final width = hdrImage.width;
      final height = hdrImage.height;
      final gainMap = img.Image(width: width, height: height);
      
      // Generate gain map based on HDR vs SDR difference
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final hdrPixel = hdrImage.getPixel(x, y);
          
          // Use base exposure frame as SDR reference
          final sdrPixel = frames.isNotEmpty ? frames[1].getPixel(x, y) : hdrPixel;
          
          // Calculate gain needed to go from SDR to HDR
          final gainR = _calculateGain(sdrPixel.r.toDouble(), hdrPixel.r.toDouble());
          final gainG = _calculateGain(sdrPixel.g.toDouble(), hdrPixel.g.toDouble());
          final gainB = _calculateGain(sdrPixel.b.toDouble(), hdrPixel.b.toDouble());
          
          // Store gain as RGB values (simplified)
          gainMap.setPixel(x, y, img.ColorRgb8(
            (gainR * 255).round().toInt().clamp(0, 255),
            (gainG * 255).round().toInt().clamp(0, 255),
            (gainB * 255).round().toInt().clamp(0, 255),
          ));
        }
      }
      
      // Encode gain map
      final gainMapData = img.encodePng(gainMap);
      return Uint8List.fromList(gainMapData);
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Gain map generation failed: $e');
      }
      rethrow;
    }
  }
  
  /// Calculate gain factor between SDR and HDR values
  double _calculateGain(double sdrValue, double hdrValue) {
    if (sdrValue == 0) return 1.0;
    final gain = hdrValue / sdrValue;
    return math.max(0.1, math.min(10.0, gain)); // Clamp gain to reasonable range
  }
  
  /// Tone map HDR image for standard displays
  Future<img.Image> _toneMapHdrImage(img.Image hdrImage) async {
    final toneMapped = img.Image.from(hdrImage);
    
    // Simple tone mapping using Reinhard operator
    for (int y = 0; y < hdrImage.height; y++) {
      for (int x = 0; x < hdrImage.width; x++) {
        final pixel = hdrImage.getPixel(x, y);
        
        // Convert to linear space
        final r = math.pow(pixel.r / 255.0, 2.2).toDouble();
        final g = math.pow(pixel.g / 255.0, 2.2).toDouble();
        final b = math.pow(pixel.b / 255.0, 2.2).toDouble();
        
        // Calculate luminance
        final luminance = 0.299 * r + 0.587 * g + 0.114 * b;
        
        // Apply Reinhard tone mapping
        final toneMappedLuminance = luminance / (1.0 + luminance);
        
        // Preserve color ratios
        final scale = luminance > 0 ? toneMappedLuminance / luminance : 1.0;
        
        // Apply tone mapping
        final toneMappedR = math.pow(r * scale, 1.0 / 2.2).toDouble();
        final toneMappedG = math.pow(g * scale, 1.0 / 2.2).toDouble();
        final toneMappedB = math.pow(b * scale, 1.0 / 2.2).toDouble();
        
        toneMapped.setPixel(x, y, img.ColorRgb8(
          (toneMappedR * 255).round().toInt().clamp(0, 255),
          (toneMappedG * 255).round().toInt().clamp(0, 255),
          (toneMappedB * 255).round().toInt().clamp(0, 255),
        ));
      }
    }
    
    return toneMapped;
  }
  
  // Configuration methods
  bool get hdrEnabled => _hdrEnabled;
  set hdrEnabled(bool value) => _hdrEnabled = value;
  
  bool get gainMapEnabled => _gainMapEnabled;
  set gainMapEnabled(bool value) => _gainMapEnabled = value;
  
  int get maxHdrFrames => _maxHdrFrames;
  set maxHdrFrames(int value) => _maxHdrFrames = math.max(1, math.min(5, value));
  
  double get bracketingRange => _bracketingRange;
  set bracketingRange(double value) => _bracketingRange = math.max(0.5, math.min(4.0, value));
  
  bool get isCapturingHdr => _isCapturingHdr;
}