import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart'; // Make sure to import the camera package
import 'package:new_app/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Create a mock CameraDescription for testing
    final mockCamera = CameraDescription(
      name: 'test_camera',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 0,
    );

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(camera: mockCamera));

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
