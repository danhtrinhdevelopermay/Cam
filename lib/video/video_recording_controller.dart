import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../video/frame_interpolation_service.dart';

enum VideoResolution {
  hd720p(Size(1280, 720), '720p'),
  fullHd1080p(Size(1920, 1080), '1080p');

  const VideoResolution(this.size, this.label);
  final Size size;
  final String label;
}

enum VideoFrameRate {
  fps30(30, '30 FPS'),
  fps60(60, '60 FPS');

  const VideoFrameRate(this.rate, this.label);
  final int rate;
  final String label;
}

class VideoRecordingSettings {
  final VideoResolution resolution;
  final VideoFrameRate frameRate;
  final bool enableAudio;

  const VideoRecordingSettings({
    required this.resolution,
    required this.frameRate,
    this.enableAudio = true,
  });

  @override
  String toString() {
    return '${resolution.label} @ ${frameRate.label}';
  }
}

class VideoRecordingController {
  CameraController? _cameraController;
  bool _isRecording = false;
  bool _isProcessing = false;
  VideoRecordingSettings _currentSettings = const VideoRecordingSettings(
    resolution: VideoResolution.hd720p,
    frameRate: VideoFrameRate.fps30,
  );
  
  final FrameInterpolationService _frameInterpolationService = FrameInterpolationService();
  
  // Getters
  bool get isRecording => _isRecording;
  bool get isProcessing => _isProcessing;
  VideoRecordingSettings get currentSettings => _currentSettings;

  void setCameraController(CameraController controller) {
    _cameraController = controller;
  }

  Future<bool> updateVideoSettings(VideoRecordingSettings settings) async {
    if (_isRecording) {
      debugPrint('Cannot change settings while recording');
      return false;
    }

    _currentSettings = settings;
    
    // Check if camera supports the requested frame rate
    if (_cameraController != null) {
      final isSupported = await _checkFrameRateSupport(settings.frameRate);
      debugPrint('Frame rate ${settings.frameRate.label} supported: $isSupported');
      return true;
    }
    
    return false;
  }

  Future<bool> _checkFrameRateSupport(VideoFrameRate frameRate) async {
    if (_cameraController == null) return false;
    
    try {
      // Try to get available frame rates for current resolution
      // This is a simplified check - in real implementation you'd query camera capabilities
      // Most devices support 30fps, some support 60fps
      return frameRate == VideoFrameRate.fps30 || frameRate == VideoFrameRate.fps60;
    } catch (e) {
      debugPrint('Frame rate check failed: $e');
      return frameRate == VideoFrameRate.fps30; // Fallback to 30fps
    }
  }

  Future<String?> startVideoRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('Camera not initialized');
      return null;
    }

    if (_isRecording) {
      debugPrint('Already recording');
      return null;
    }

    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = '${tempDir.path}/video_${timestamp}_${_currentSettings.resolution.label}_raw.mp4';

      // Configure recording settings
      await _configureRecordingSettings();

      await _cameraController!.startVideoRecording();
      _isRecording = true;
      
      debugPrint('Started recording: $filePath');
      debugPrint('Settings: ${_currentSettings.toString()}');
      
      return filePath;
    } catch (e) {
      debugPrint('Failed to start recording: $e');
      return null;
    }
  }

  Future<void> _configureRecordingSettings() async {
    if (_cameraController == null) return;

    try {
      // Set focus and exposure for video recording
      await _cameraController!.setFocusMode(FocusMode.locked);
      await _cameraController!.setExposureMode(ExposureMode.locked);
      
      // Additional video-specific configurations could be added here
      // Note: Direct frame rate control depends on camera plugin capabilities
    } catch (e) {
      debugPrint('Failed to configure recording settings: $e');
    }
  }

  Future<String?> stopVideoRecording() async {
    if (_cameraController == null || !_isRecording) {
      debugPrint('Not recording or camera not available');
      return null;
    }

    try {
      final XFile recordedFile = await _cameraController!.stopVideoRecording();
      _isRecording = false;
      
      debugPrint('Stopped recording: ${recordedFile.path}');

      // Process video if needed (frame interpolation for 60fps on unsupported devices)
      final String? processedPath = await _processRecordedVideo(recordedFile.path);
      
      return processedPath ?? recordedFile.path;
    } catch (e) {
      debugPrint('Failed to stop recording: $e');
      _isRecording = false;
      return null;
    }
  }

  Future<String?> _processRecordedVideo(String inputPath) async {
    // Check if frame interpolation is needed
    final bool needsInterpolation = _currentSettings.frameRate == VideoFrameRate.fps60 &&
                                   !await _checkFrameRateSupport(VideoFrameRate.fps60);
    
    if (!needsInterpolation) {
      debugPrint('No video processing needed');
      return inputPath; // Return original file
    }

    debugPrint('Starting frame interpolation for 60fps...');
    _isProcessing = true;

    try {
      final String? interpolatedPath = await _frameInterpolationService.interpolateVideoTo60fps(
        inputPath: inputPath,
        resolution: _currentSettings.resolution,
      );

      _isProcessing = false;
      
      if (interpolatedPath != null) {
        debugPrint('Frame interpolation completed: $interpolatedPath');
        // Clean up original file
        try {
          await File(inputPath).delete();
        } catch (e) {
          debugPrint('Failed to clean up original file: $e');
        }
        return interpolatedPath;
      } else {
        debugPrint('Frame interpolation failed, using original video');
        return inputPath;
      }
    } catch (e) {
      debugPrint('Video processing error: $e');
      _isProcessing = false;
      return inputPath; // Return original on error
    }
  }

  List<VideoResolution> getSupportedResolutions() {
    return VideoResolution.values;
  }

  List<VideoFrameRate> getSupportedFrameRates() {
    return VideoFrameRate.values;
  }

  Future<void> dispose() async {
    _isRecording = false;
    _isProcessing = false;
    await _frameInterpolationService.dispose();
  }

  String getRecordingStatusText() {
    if (_isProcessing) {
      return 'Processing video with AI frame interpolation...';
    } else if (_isRecording) {
      return 'Recording ${_currentSettings.toString()}...';
    } else {
      return 'Ready to record ${_currentSettings.toString()}';
    }
  }
}