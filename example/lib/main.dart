import 'dart:io';

import 'package:flutter/material.dart';

import 'package:face_camera/face_camera.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FaceCamera.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  File? _capturedImage;

  late FaceCameraController controller;

  @override
  void initState() {
    controller = FaceCameraController(
      autoCapture: true,
      captureDelay: 3,
      defaultCameraLens: CameraLens.front,
      showDebugLandmarks: false, // Set true to see facial landmarks
      onCapture: (File? image) {
        setState(() => _capturedImage = image);
      },
      onFaceDetected: (Face? face) {
        //Do something
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('FaceCamera example app'),
          ),
          body: Builder(builder: (context) {
            if (_capturedImage != null) {
              return Center(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Image.file(
                      _capturedImage!,
                      width: double.maxFinite,
                      fit: BoxFit.fitWidth,
                    ),
                    ElevatedButton(
                        onPressed: () async {
                          await controller.startImageStream();
                          setState(() => _capturedImage = null);
                        },
                        child: const Text(
                          'Capture Again',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ))
                  ],
                ),
              );
            }
            return SmartFaceCamera(
                controller: controller,
                indicatorShape: IndicatorShape.fixedFrame,
                messageBuilder: (context, face) {
                  // Show countdown message
                  if (controller.value.countdown != null) {
                    return _message('Hold still...');
                  }

                  // Get positioning guidance
                  final guidance = controller.getFacePositionGuidance();
                  if (guidance != null) {
                    return _message(_customizeMessage(guidance));
                  }

                  return const SizedBox.shrink();
                });
          })),
    );
  }

  Widget _message(String msg) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 15),
        child: Text(msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14, height: 1.5, fontWeight: FontWeight.w400)),
      );

  String _customizeMessage(String guidance) {
    // Customize guidance messages here
    switch (guidance) {
      case 'Move closer':
        return 'Come closer to the camera';
      case 'Move back':
        return 'Move away from the camera';
      case 'Move left':
      case 'Move right':
      case 'Move up':
      case 'Move down':
        return guidance; // Keep directional messages as-is
      case 'Center your face':
        return 'Almost there! Center your face';
      case 'Place your face in the frame':
        return 'Position your face in the frame';
      default:
        return guidance;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
