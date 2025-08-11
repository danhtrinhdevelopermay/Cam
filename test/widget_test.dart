import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';
import 'package:ios18_camera_app/main.dart';

void main() {
  testWidgets('iOS18 Camera App smoke test', (WidgetTester tester) async {
    // Create mock camera future for testing
    final mockCameraFuture = Future.value(<CameraDescription>[]);
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(iOS18CameraApp(cameraInitFuture: mockCameraFuture));
    
    // Wait for future to complete
    await tester.pump();

    // Verify that our app shows no camera screen when no cameras available
    expect(find.text('No Camera Available'), findsOneWidget);
    expect(find.text('Please check camera permissions'), findsOneWidget);
  });

  testWidgets('Camera app shows camera icon when no cameras', (WidgetTester tester) async {
    // Create mock camera future for testing
    final mockCameraFuture = Future.value(<CameraDescription>[]);
    
    await tester.pumpWidget(iOS18CameraApp(cameraInitFuture: mockCameraFuture));
    
    // Wait for future to complete
    await tester.pump();
    
    // Should show camera icon
    expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
  });
}