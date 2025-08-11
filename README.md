# iOS 18 Style Camera App

An Android camera application built with Flutter that mimics the iOS 18 camera interface with beautiful Gaussian blur effects and modern design elements.

## Features

- **iOS 18-style Interface**: Clean, modern design inspired by iOS 18 camera app
- **Gaussian Blur Effects**: Beautiful blur animations and glass morphism effects
- **Camera Controls**: 
  - Photo capture with tap-to-focus
  - Front/rear camera switching
  - Flash toggle
  - Zoom controls
- **Mode Selection**: Time-lapse, Slo-mo, Video, Photo, Portrait modes
- **Permissions Handling**: Automatic camera and storage permissions
- **Gallery Integration**: Save photos directly to device gallery

## Technologies Used

- **Flutter**: Cross-platform mobile development framework
- **Dart**: Programming language
- **Camera Plugin**: Access device cameras
- **Image Filters**: Gaussian blur and glass effects
- **Material Design 3**: Modern UI components
- **GitHub Actions**: Automated APK building and releases

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/
│   └── camera_screen.dart    # Main camera interface
└── widgets/
    ├── blur_overlay.dart     # Blur effect components
    ├── camera_controls.dart  # Camera control buttons
    └── mode_selector.dart    # Mode selection widget

android/                      # Android-specific configuration
├── app/
│   ├── build.gradle         # App-level build configuration
│   └── src/main/
│       ├── AndroidManifest.xml  # App permissions and settings
│       └── kotlin/          # Kotlin MainActivity

.github/workflows/
└── build_apk.yml           # GitHub Actions for APK building
```

## Installation & Setup

### Prerequisites
- Flutter SDK (3.16.0 or higher)
- Android Studio / VS Code
- Android SDK
- Git

### Getting Started

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd ios18-camera-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## GitHub Actions Setup

The project includes automated APK building through GitHub Actions:

1. **Push code to GitHub**
   ```bash
   git add .
   git commit -m "feat: initial camera app implementation"
   git push origin main
   ```

2. **Automatic Build Process**:
   - Triggers on push to main/master branch
   - Runs Flutter tests and analysis
   - Builds release APK
   - Creates GitHub release with APK download

3. **Download APK**:
   - Check the "Actions" tab in your GitHub repository
   - Download the built APK from "Releases" section

## Permissions

The app requires the following Android permissions:
- `CAMERA`: Access device camera
- `RECORD_AUDIO`: Record video with audio
- `WRITE_EXTERNAL_STORAGE`: Save photos/videos
- `READ_EXTERNAL_STORAGE`: Access saved media
- `INTERNET`: Network access for updates

## Development Workflow

Following the Vietnamese development guidelines:

1. **Make code changes**
2. **Test locally**: `flutter run`
3. **Push to GitHub**: 
   ```bash
   git add .
   git commit -m "description of changes"
   git push origin main
   ```
4. **Check for errors** in GitHub Actions
5. **Fix any build issues** immediately
6. **Prevent APK build failures** by testing thoroughly

## Camera Features

### Photo Mode
- Tap anywhere to focus
- Pinch to zoom (1x - 10x)
- Automatic photo saving to gallery
- Flash control

### Interface Elements
- **Blur Effects**: Smooth Gaussian blur animations
- **Glass Morphism**: Translucent control panels
- **iOS 18 Design**: Faithful recreation of iOS camera UI
- **Dark Theme**: Optimized for camera usage

## Building APK Manually

```bash
# Build release APK
flutter build apk --release

# Build AAB (for Play Store)
flutter build appbundle --release
```

## Troubleshooting

### Common Issues
1. **Camera not working**: Check device permissions
2. **Build failures**: Ensure Flutter SDK is up to date
3. **GitHub Actions failing**: Check YAML syntax and Flutter version

### Error Prevention
- Always test locally before pushing
- Check `flutter doctor` for setup issues
- Verify all dependencies are compatible
- Test on physical device for camera functionality

## Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-feature`
3. Commit changes: `git commit -m "feat: add new feature"`
4. Push to branch: `git push origin feature/new-feature`
5. Submit pull request

## License

This project is open source and available under the [MIT License](LICENSE).