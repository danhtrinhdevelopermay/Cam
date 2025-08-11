import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:vector_math/vector_math.dart' as vm;
import 'dart:math' as math;

/// iOS 18-style color processing controller
/// Implements advanced HDR, wide color gamut, and Apple-like tone mapping
class ColorProcessingController {
  // Note: P3 and sRGB conversion matrices would be used in real color space conversion
  // For this implementation, we simulate P3 enhancement through selective color boosting

  // iOS 18 calibration settings
  bool _hdrEnabled = true;
  bool _displayP3Enabled = true;
  bool _adaptiveHdrEnabled = true;
  double _saturationBoost = 1.15; // Slight boost for blues and greens
  double _skinTonePreservation = 0.85; // Keep skin tones natural
  double _whiteBalanceAdaptation = 0.8;
  double _shadowDetail = 0.3;
  double _highlightRecovery = 0.4;
  double _noiseReduction = 0.2; // Light noise reduction
  
  // Auto white balance state
  double _currentColorTemperature = 5500; // Neutral starting point
  double _targetColorTemperature = 5500;
  
  // HDR state managed by HdrCaptureController
  
  /// Configure camera settings for wide color gamut and HDR
  Future<void> configureCameraForAdvancedColor(CameraController controller) async {
    try {
      if (!controller.value.isInitialized) return;
      
      // Configure for maximum color depth and HDR capability
      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);
      
      // Enable HDR mode if supported
      if (_hdrEnabled) {
        // Note: Real HDR capture would require platform-specific implementation
        // For now, we'll simulate with multi-frame capture and tone mapping
        if (kDebugMode) {
          print('🎨 HDR mode enabled for advanced color processing');
        }
      }
      
      if (kDebugMode) {
        print('🌈 Advanced color processing configured:');
        print('   HDR enabled: $_hdrEnabled');
        print('   Display P3 enabled: $_displayP3Enabled');
        print('   Adaptive tone mapping: $_adaptiveHdrEnabled');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error configuring advanced color: $e');
      }
    }
  }
  
  /// Process image with iOS 18-style color enhancement
  Future<Uint8List> processImageWithAdvancedColor(Uint8List imageData) async {
    try {
      // Decode image
      final image = img.decodeImage(imageData);
      if (image == null) return imageData;
      
      // Create working copy
      var processedImage = img.Image.from(image);
      
      // Apply iOS 18-style processing pipeline
      processedImage = await _applyAdvancedColorPipeline(processedImage);
      
      // Encode back to JPEG with high quality
      final processedData = img.encodeJpg(processedImage, quality: 95);
      return Uint8List.fromList(processedData);
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in advanced color processing: $e');
      }
      return imageData; // Return original on error
    }
  }
  
  /// Apply the complete iOS 18-style color processing pipeline
  Future<img.Image> _applyAdvancedColorPipeline(img.Image image) async {
    var processed = image;
    
    // 1. Auto white balance with smooth transitions
    processed = _applyAdaptiveWhiteBalance(processed);
    
    // 2. HDR tone mapping with highlight/shadow recovery
    processed = _applyAdaptiveHdrToneMapping(processed);
    
    // 3. Apple-like color calibration
    processed = _applyAppleColorCalibration(processed);
    
    // 4. Smart saturation enhancement
    processed = _applySmartSaturationEnhancement(processed);
    
    // 5. Skin tone preservation
    processed = _applySkinTonePreservation(processed);
    
    // 6. Light noise reduction
    processed = _applyLightNoiseReduction(processed);
    
    // 7. Wide color gamut mapping (P3 simulation)
    if (_displayP3Enabled) {
      processed = _applyWideColorGamutMapping(processed);
    }
    
    return processed;
  }
  
  /// Apply adaptive white balance similar to iOS
  img.Image _applyAdaptiveWhiteBalance(img.Image image) {
    // Analyze image color temperature
    final detectedTemp = _analyzeColorTemperature(image);
    
    // Smooth transition to new temperature
    _targetColorTemperature = detectedTemp;
    _currentColorTemperature = _lerp(_currentColorTemperature, _targetColorTemperature, _whiteBalanceAdaptation);
    
    // Apply white balance correction
    final tempCorrection = _calculateWhiteBalanceCorrection(_currentColorTemperature);
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r * tempCorrection.x;
        final g = pixel.g * tempCorrection.y;
        final b = pixel.b * tempCorrection.z;
        
        image.setPixel(x, y, img.ColorRgb8(
          _clamp(r.round(), 0, 255),
          _clamp(g.round(), 0, 255),
          _clamp(b.round(), 0, 255),
        ));
      }
    }
    
    return image;
  }
  
  /// Apply HDR tone mapping with adaptive highlight/shadow recovery
  img.Image _applyAdaptiveHdrToneMapping(img.Image image) {
    // Calculate luminance statistics
    final luminanceStats = _calculateLuminanceStatistics(image);
    final avgLuminance = luminanceStats['average']!;
    final maxLuminance = luminanceStats['max']!;
    
    // Adaptive tone mapping parameters based on scene analysis
    final shadowLift = _shadowDetail * (1.0 - avgLuminance);
    final highlightRolloff = _highlightRecovery * (maxLuminance / 255.0);
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        
        // Convert to floating point
        double r = pixel.r / 255.0;
        double g = pixel.g / 255.0;
        double b = pixel.b / 255.0;
        
        // Calculate luminance
        double luminance = 0.299 * r + 0.587 * g + 0.114 * b;
        
        // Apply iOS 18-style tone curve
        double toneMapped = _appleStyleToneCurve(luminance, shadowLift, highlightRolloff);
        double adjustment = toneMapped / math.max(luminance, 0.001);
        
        // Apply adjustment while preserving color relationships
        r = _clamp01(r * adjustment);
        g = _clamp01(g * adjustment);
        b = _clamp01(b * adjustment);
        
        image.setPixel(x, y, img.ColorRgb8(
          (r * 255).round(),
          (g * 255).round(),
          (b * 255).round(),
        ));
      }
    }
    
    return image;
  }
  
  /// Apply Apple-like color calibration with accurate skin tones
  img.Image _applyAppleColorCalibration(img.Image image) {
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        
        // Convert to HSV for easier color manipulation
        final hsv = _rgbToHsv(pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0);
        
        // Apple-like hue adjustments
        double adjustedHue = _applyAppleHueAdjustments(hsv.x);
        double adjustedSaturation = _applyAppleSaturationAdjustments(hsv.x, hsv.y);
        
        // Convert back to RGB
        final rgb = _hsvToRgb(adjustedHue, adjustedSaturation, hsv.z);
        
        image.setPixel(x, y, img.ColorRgb8(
          (rgb.x * 255).round(),
          (rgb.y * 255).round(),
          (rgb.z * 255).round(),
        ));
      }
    }
    
    return image;
  }
  
  /// Apply smart saturation enhancement (boost blues/greens, preserve reds)
  img.Image _applySmartSaturationEnhancement(img.Image image) {
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final hsv = _rgbToHsv(pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0);
        
        // Smart saturation based on hue
        double saturationMultiplier = 1.0;
        
        // Boost blues (180-240 degrees)
        if (hsv.x >= 180 && hsv.x <= 240) {
          saturationMultiplier = _saturationBoost;
        }
        // Boost greens (90-150 degrees) 
        else if (hsv.x >= 90 && hsv.x <= 150) {
          saturationMultiplier = _saturationBoost * 0.9;
        }
        // Keep reds natural (0-30, 330-360 degrees)
        else if (hsv.x <= 30 || hsv.x >= 330) {
          saturationMultiplier = 1.0;
        }
        
        final newSaturation = _clamp01(hsv.y * saturationMultiplier);
        final rgb = _hsvToRgb(hsv.x, newSaturation, hsv.z);
        
        image.setPixel(x, y, img.ColorRgb8(
          (rgb.x * 255).round(),
          (rgb.y * 255).round(),
          (rgb.z * 255).round(),
        ));
      }
    }
    
    return image;
  }
  
  /// Preserve natural skin tones
  img.Image _applySkinTonePreservation(img.Image image) {
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final hsv = _rgbToHsv(pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0);
        
        // Detect skin tone hues (roughly 0-50 degrees)
        if (_isSkinTone(hsv.x, hsv.y, hsv.z)) {
          // Reduce saturation adjustments for skin tones
          final originalRgb = _hsvToRgb(hsv.x, hsv.y, hsv.z);
          final currentRgb = vm.Vector3(pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0);
          
          // Blend towards natural skin tone
          final preservedRgb = vm.Vector3(
            _lerp(currentRgb.x, originalRgb.x, _skinTonePreservation),
            _lerp(currentRgb.y, originalRgb.y, _skinTonePreservation),
            _lerp(currentRgb.z, originalRgb.z, _skinTonePreservation),
          );
          
          image.setPixel(x, y, img.ColorRgb8(
            (preservedRgb.x * 255).round(),
            (preservedRgb.y * 255).round(),
            (preservedRgb.z * 255).round(),
          ));
        }
      }
    }
    
    return image;
  }
  
  /// Apply light noise reduction while preserving details
  img.Image _applyLightNoiseReduction(img.Image image) {
    if (_noiseReduction <= 0) return image;
    
    // Simple bilateral filter approximation for noise reduction
    final filtered = img.Image.from(image);
    final radius = 1;
    
    for (int y = radius; y < image.height - radius; y++) {
      for (int x = radius; x < image.width - radius; x++) {
        double totalR = 0, totalG = 0, totalB = 0;
        double weightSum = 0;
        
        for (int dy = -radius; dy <= radius; dy++) {
          for (int dx = -radius; dx <= radius; dx++) {
            final neighborPixel = image.getPixel(x + dx, y + dy);
            final centerPixel = image.getPixel(x, y);
            
            // Spatial weight
            double spatialWeight = math.exp(-(dx * dx + dy * dy) / (2 * radius * radius));
            
            // Intensity difference weight
            double intensityDiff = _calculatePixelDistance(centerPixel, neighborPixel);
            double intensityWeight = math.exp(-intensityDiff / (2 * _noiseReduction * 255));
            
            double weight = spatialWeight * intensityWeight;
            
            totalR += neighborPixel.r * weight;
            totalG += neighborPixel.g * weight;
            totalB += neighborPixel.b * weight;
            weightSum += weight;
          }
        }
        
        if (weightSum > 0) {
          filtered.setPixel(x, y, img.ColorRgb8(
            (totalR / weightSum).round(),
            (totalG / weightSum).round(),
            (totalB / weightSum).round(),
          ));
        }
      }
    }
    
    return filtered;
  }
  
  /// Apply wide color gamut mapping (Display P3 simulation)
  img.Image _applyWideColorGamutMapping(img.Image image) {
    // For now, simulate P3 by enhancing color vibrancy in a controlled way
    // Real P3 support would require platform-specific color management
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        
        // Convert to linear RGB for color space operations
        var r = _srgbToLinear(pixel.r / 255.0);
        var g = _srgbToLinear(pixel.g / 255.0);
        var b = _srgbToLinear(pixel.b / 255.0);
        
        // Simulate P3 gamut expansion
        final p3Enhanced = _simulateP3Enhancement(r, g, b);
        
        // Convert back to sRGB
        r = _linearToSrgb(p3Enhanced.x);
        g = _linearToSrgb(p3Enhanced.y);
        b = _linearToSrgb(p3Enhanced.z);
        
        image.setPixel(x, y, img.ColorRgb8(
          (r * 255).round(),
          (g * 255).round(),
          (b * 255).round(),
        ));
      }
    }
    
    return image;
  }
  
  // Helper methods
  
  double _analyzeColorTemperature(img.Image image) {
    double totalR = 0, totalB = 0;
    int pixelCount = 0;
    
    // Sample every 10th pixel for performance
    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        totalR += pixel.r;
        totalB += pixel.b;
        pixelCount++;
      }
    }
    
    if (pixelCount == 0) return 5500;
    
    final avgR = totalR / pixelCount;
    final avgB = totalB / pixelCount;
    
    // Estimate color temperature from RGB ratios
    final rOverB = avgR / math.max(avgB, 1);
    
    // Map ratio to temperature (simplified)
    if (rOverB > 1.2) return 3000; // Warm
    if (rOverB > 1.1) return 4000;
    if (rOverB > 0.9) return 5500; // Neutral
    if (rOverB > 0.8) return 6500;
    return 8000; // Cool
  }
  
  vm.Vector3 _calculateWhiteBalanceCorrection(double temperature) {
    // Simple white balance correction based on temperature
    double rGain = 1.0;
    double gGain = 1.0;
    double bGain = 1.0;
    
    if (temperature < 5500) {
      // Warm light - reduce red, boost blue
      rGain = 1.0 - (5500 - temperature) / 5500 * 0.2;
      bGain = 1.0 + (5500 - temperature) / 5500 * 0.3;
    } else {
      // Cool light - boost red, reduce blue
      rGain = 1.0 + (temperature - 5500) / 3000 * 0.2;
      bGain = 1.0 - (temperature - 5500) / 3000 * 0.3;
    }
    
    return vm.Vector3(rGain, gGain, bGain);
  }
  
  Map<String, double> _calculateLuminanceStatistics(img.Image image) {
    double total = 0;
    double max = 0;
    double min = 255;
    int count = 0;
    
    for (int y = 0; y < image.height; y += 2) {
      for (int x = 0; x < image.width; x += 2) {
        final pixel = image.getPixel(x, y);
        final luminance = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
        
        total += luminance;
        max = math.max(max, luminance);
        min = math.min(min, luminance);
        count++;
      }
    }
    
    return {
      'average': total / count / 255.0,
      'max': max,
      'min': min,
    };
  }
  
  double _appleStyleToneCurve(double input, double shadowLift, double highlightRolloff) {
    // Apple's tone curve approximation
    double x = input;
    
    // Shadow lift
    x = x + shadowLift * (1.0 - x) * x;
    
    // Highlight rolloff using smooth curve
    if (x > 0.7) {
      double t = (x - 0.7) / 0.3;
      x = 0.7 + 0.3 * (1.0 - math.pow(1.0 - t, 1.0 + highlightRolloff));
    }
    
    // S-curve for contrast
    x = _smoothstep(0.0, 1.0, x);
    
    return _clamp01(x);
  }
  
  vm.Vector3 _rgbToHsv(double r, double g, double b) {
    final max = math.max(math.max(r, g), b);
    final min = math.min(math.min(r, g), b);
    final delta = max - min;
    
    double h = 0;
    double s = max == 0 ? 0 : delta / max;
    double v = max;
    
    if (delta != 0) {
      if (max == r) {
        h = 60 * ((g - b) / delta % 6);
      } else if (max == g) {
        h = 60 * ((b - r) / delta + 2);
      } else {
        h = 60 * ((r - g) / delta + 4);
      }
    }
    
    if (h < 0) h += 360;
    
    return vm.Vector3(h, s, v);
  }
  
  vm.Vector3 _hsvToRgb(double h, double s, double v) {
    final c = v * s;
    final x = c * (1 - (((h / 60) % 2) - 1).abs());
    final m = v - c;
    
    double r = 0, g = 0, b = 0;
    
    if (h >= 0 && h < 60) {
      r = c; g = x; b = 0;
    } else if (h >= 60 && h < 120) {
      r = x; g = c; b = 0;
    } else if (h >= 120 && h < 180) {
      r = 0; g = c; b = x;
    } else if (h >= 180 && h < 240) {
      r = 0; g = x; b = c;
    } else if (h >= 240 && h < 300) {
      r = x; g = 0; b = c;
    } else if (h >= 300 && h < 360) {
      r = c; g = 0; b = x;
    }
    
    return vm.Vector3(r + m, g + m, b + m);
  }
  
  double _applyAppleHueAdjustments(double hue) {
    // Apple's hue adjustments for natural colors
    if (hue >= 0 && hue <= 60) {
      // Red-orange: slight shift towards warmer tones
      return hue + (hue / 60.0) * 5;
    } else if (hue >= 60 && hue <= 180) {
      // Yellow-green: enhance green vibrancy
      return hue + math.sin((hue - 60) / 120 * math.pi) * 8;
    } else if (hue >= 180 && hue <= 300) {
      // Cyan-blue-magenta: enhance blue depth
      return hue + math.sin((hue - 180) / 120 * math.pi) * 6;
    }
    
    return hue;
  }
  
  double _applyAppleSaturationAdjustments(double hue, double saturation) {
    double multiplier = 1.0;
    
    // Sky blues
    if (hue >= 180 && hue <= 240) {
      multiplier = 1.2;
    }
    // Grass greens  
    else if (hue >= 90 && hue <= 150) {
      multiplier = 1.15;
    }
    // Skin tones
    else if (hue <= 30 || hue >= 330) {
      multiplier = 0.95;
    }
    
    return _clamp01(saturation * multiplier);
  }
  
  bool _isSkinTone(double h, double s, double v) {
    // Detect likely skin tones
    return (h <= 50 || h >= 330) && s >= 0.2 && s <= 0.7 && v >= 0.3;
  }
  
  double _calculatePixelDistance(img.Color p1, img.Color p2) {
    return math.sqrt(
      math.pow(p1.r - p2.r, 2) + 
      math.pow(p1.g - p2.g, 2) + 
      math.pow(p1.b - p2.b, 2)
    );
  }
  
  double _srgbToLinear(double value) {
    return value <= 0.04045 
        ? value / 12.92 
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }
  
  double _linearToSrgb(double value) {
    return value <= 0.0031308 
        ? value * 12.92 
        : 1.055 * math.pow(value, 1.0 / 2.4).toDouble() - 0.055;
  }
  
  vm.Vector3 _simulateP3Enhancement(double r, double g, double b) {
    // Simulate P3 wider gamut by selectively enhancing colors
    final saturation = math.max(math.max(r, g), b) - math.min(math.min(r, g), b);
    final enhancement = math.min(saturation * 0.15, 0.1);
    
    return vm.Vector3(
      _clamp01(r + (r > g && r > b ? enhancement : 0)),
      _clamp01(g + (g > r && g > b ? enhancement : 0)),
      _clamp01(b + (b > r && b > g ? enhancement : 0)),
    );
  }
  
  double _smoothstep(double edge0, double edge1, double x) {
    final t = _clamp01((x - edge0) / (edge1 - edge0));
    return t * t * (3.0 - 2.0 * t);
  }
  
  double _lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }
  
  double _clamp01(double value) {
    return math.max(0.0, math.min(1.0, value));
  }
  
  int _clamp(int value, int min, int max) {
    return math.max(min, math.min(max, value));
  }
  
  // Getters and setters for configuration
  bool get hdrEnabled => _hdrEnabled;
  set hdrEnabled(bool value) => _hdrEnabled = value;
  
  bool get displayP3Enabled => _displayP3Enabled;
  set displayP3Enabled(bool value) => _displayP3Enabled = value;
  
  bool get adaptiveHdrEnabled => _adaptiveHdrEnabled;
  set adaptiveHdrEnabled(bool value) => _adaptiveHdrEnabled = value;
  
  double get saturationBoost => _saturationBoost;
  set saturationBoost(double value) => _saturationBoost = _clamp01(value * 2);
  
  double get shadowDetail => _shadowDetail;
  set shadowDetail(double value) => _shadowDetail = _clamp01(value);
  
  double get highlightRecovery => _highlightRecovery;
  set highlightRecovery(double value) => _highlightRecovery = _clamp01(value);
  
  double get noiseReduction => _noiseReduction;
  set noiseReduction(double value) => _noiseReduction = _clamp01(value);
}