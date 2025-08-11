import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'screens/camera_screen.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style for iOS 18 look immediately
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize cameras in parallel with app startup
  final cameraInitFuture = _initializeCameras();
  
  // Start app immediately, camera will initialize in background
  runApp(iOS18CameraApp(cameraInitFuture: cameraInitFuture));
}

Future<List<CameraDescription>> _initializeCameras() async {
  try {
    print('Attempting to initialize cameras...');
    final cameras = await availableCameras();
    print('Found ${cameras.length} cameras');
    for (int i = 0; i < cameras.length; i++) {
      print('Camera $i: ${cameras[i].name} - ${cameras[i].lensDirection}');
    }
    return cameras;
  } on CameraException catch (e) {
    print('Camera Error: ${e.code}\nError Message: ${e.description}');
    return [];
  } catch (e) {
    print('Unexpected camera error: $e');
    return [];
  }
}

class iOS18CameraApp extends StatelessWidget {
  final Future<List<CameraDescription>> cameraInitFuture;
  
  const iOS18CameraApp({super.key, required this.cameraInitFuture});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iOS18 Camera',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: FutureBuilder<List<CameraDescription>>(
        future: cameraInitFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CameraLoadingScreen();
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return CameraScreen(cameras: snapshot.data!);
          } else {
            return const NoCameraScreen();
          }
        },
      ),
    );
  }
}

class CameraLoadingScreen extends StatelessWidget {
  const CameraLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
            const SizedBox(height: 20),
            Text(
              'Initializing Camera...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoCameraScreen extends StatelessWidget {
  const NoCameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'No Camera Available',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Please check camera permissions',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}