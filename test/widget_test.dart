import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios18_camera_app/main.dart';

void main() {
  testWidgets('iOS18 Camera App smoke test', (WidgetTester tester) async {
    // Initialize cameras for testing
    cameras = [];
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(const iOS18CameraApp());

    // Verify that our app shows no camera screen when no cameras available
    expect(find.text('No Camera Available'), findsOneWidget);
    expect(find.text('Please check camera permissions'), findsOneWidget);
  });

  testWidgets('Camera app shows camera icon when no cameras', (WidgetTester tester) async {
    cameras = [];
    
    await tester.pumpWidget(const iOS18CameraApp());
    
    // Should show camera icon
    expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
  });
}