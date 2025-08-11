# Replit Configuration

## Overview

iOS 18-style camera application built with Flutter for Android. Features include Gaussian blur effects, modern glass morphism UI, camera controls (photo/video capture, zoom, flash, camera switching), mode selection, aspect ratio adjustment (Full, 16:9, 4:3, 1:1), advanced 10x zoom with optical zoom detection, high-resolution crop, AI super resolution, multi-frame stacking, and automated APK building via GitHub Actions. The project emphasizes preventing build failures and maintaining code quality through manual testing before deployment.

## User Preferences

Preferred communication style: Simple, everyday language.

### Development Workflow Preferences (from loinhac.md):
- Every code change should include manual push commands to GitHub
- After each push, check for errors and fix them immediately  
- Focus on preventing errors during APK building in GitHub Actions

### Recent Build Fixes (August 11, 2025):
- Resolved all GitHub Actions build failures through comprehensive fixes
- Fixed deprecated actions, Gradle wrapper issues, packaging syntax errors
- Created complete Android resources (icons, themes, drawables, manifest)
- Updated to SDK 34 for camera plugin compatibility

### Advanced 10x Zoom Feature (August 11, 2025):
- Implemented comprehensive 10x zoom system with four enhancement methods
- Added optical zoom detection for telephoto and periscope cameras
- Integrated high-resolution capture and crop functionality
- Added AI super resolution service with Real-ESRGAN and Waifu2x support
- Implemented multi-frame image stacking for noise reduction
- Created advanced zoom controls with iOS 18-style interface
- Added zoom settings panel for method configuration

## System Architecture

### Flutter Mobile Application Structure
- **Main App**: `lib/main.dart` - Entry point with camera initialization
- **Camera Screen**: `lib/screens/camera_screen.dart` - Core camera interface with iOS 18 styling
- **UI Components**: 
  - `lib/widgets/blur_overlay.dart` - Gaussian blur effects and glass morphism
  - `lib/widgets/camera_controls.dart` - Photo capture, gallery, camera switch controls
  - `lib/widgets/mode_selector.dart` - Time-lapse, Video, Photo, Portrait mode selection
  - `lib/widgets/aspect_ratio_selector.dart` - Aspect ratio adjustment (Full, 16:9, 4:3, 1:1)
  - `lib/widgets/advanced_zoom_controls.dart` - Advanced 10x zoom interface with method indicators
  - `lib/widgets/zoom_settings_panel.dart` - Configuration panel for zoom enhancement methods
- **Advanced Zoom System**:
  - `lib/camera/advanced_zoom_controller.dart` - Core zoom orchestration and enhancement methods
  - `lib/ai/super_resolution_service.dart` - AI enhancement with Real-ESRGAN and Waifu2x integration

### Android Configuration
- **Build**: `android/app/build.gradle` - Android build configuration with camera permissions
- **Permissions**: Camera, audio recording, storage access via AndroidManifest.xml
- **MainActivity**: Kotlin-based Flutter activity launcher

### Development Workflow
- Flutter development with hot reload capability
- Manual GitHub push with automated APK building
- Error prevention focus during GitHub Actions CI/CD
- Comprehensive testing before deployment

### Build System
- **GitHub Actions**: `.github/workflows/build_apk.yml` - Automated Flutter APK building
- **Dependencies**: Camera, image processing, permission handling, blur effects
- **Release**: Automatic APK artifact creation and GitHub releases

## External Dependencies

### Flutter & Dart
- **Flutter SDK**: 3.16.0+ for cross-platform mobile development
- **Dart**: Programming language for Flutter development
- **Camera Plugin**: Device camera access and control
- **Image Processing**: Gaussian blur, filters, gallery saving
- **Permissions**: Runtime permission handling for camera and storage

### Version Control & CI/CD
- **GitHub**: Repository hosting with automated workflows
- **GitHub Actions**: Flutter APK building, testing, and release automation
- **Android SDK**: Build tools for APK generation

### UI Libraries
- **Material Design 3**: Modern UI components
- **Image Filters**: Blur effects and visual processing
- **Cupertino Icons**: iOS-style iconography