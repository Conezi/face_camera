import 'dart:async';
import 'dart:io';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:lottie/lottie.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../face_camera.dart';
import 'handlers/emun_handler.dart';
import 'handlers/face_identifier.dart';
import 'models/scanned_image.dart';
import 'paints/face_painter.dart';
import 'paints/hole_painter.dart';
import 'res/builders.dart';
import 'utils/logger.dart';

class SmartFaceCamera extends StatefulWidget {
  final bool showControls;
  final bool showCaptureControl;

  final bool showCameraLensControl;
  final String? message;
  final TextStyle messageStyle;
  final Future Function(File? image, Face? face) onCapture;
  final Widget? captureControlIcon;
  final Widget? lensControlIcon;
  final MessageBuilder? messageBuilder;

  const SmartFaceCamera(
      {this.showControls = true,
      this.showCaptureControl = true,
      this.showCameraLensControl = true,
      this.message,
      this.messageStyle = const TextStyle(
          fontSize: 14, height: 1.5, fontWeight: FontWeight.w400),
      required this.onCapture,
      this.captureControlIcon,
      this.lensControlIcon,
      this.messageBuilder,
      Key? key})
      : super(key: key);

  @override
  _SmartFaceCameraState createState() => _SmartFaceCameraState();
}

class _SmartFaceCameraState extends State<SmartFaceCamera>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;

  bool _alreadyCheckingImage = false;

  DetectedFace? _detectedFace;

  int _currentCameraLens = 0;
  final List<CameraLens> _avaliableCameraLens = [];

  Future<CameraDescription> _getCameraDescription() async {
    List<CameraDescription> cameras = await availableCameras();
    return cameras.firstWhere((CameraDescription camera) =>
        camera.lensDirection == CameraLensDirection.front);
  }

  Future<void> _initCamera() async {
    if (_controller != null) return;
    CameraDescription description = await _getCameraDescription();
    _controller = CameraController(description, ResolutionPreset.high,
        enableAudio: false);
    await _controller?.initialize();

    CameraOrientation? orientation = CameraOrientation.portraitUp;
    final nativeOrientation = await NativeDeviceOrientationCommunicator()
        .orientation(useSensor: true);
    switch (nativeOrientation) {
      case NativeDeviceOrientation.landscapeLeft:
        orientation = CameraOrientation.landscapeRight;
        break;
      case NativeDeviceOrientation.landscapeRight:
        orientation = CameraOrientation.landscapeLeft;
        break;
      case NativeDeviceOrientation.portraitDown:
        orientation = CameraOrientation.portraitDown;
        break;
      case NativeDeviceOrientation.portraitUp:
        orientation = CameraOrientation.portraitUp;
        break;

      default:
        break;
    }
    await _controller!
        .lockCaptureOrientation(
            EnumHandler.cameraOrientationToDeviceOrientation(orientation))
        .then((_) {
      if (mounted) setState(() {});
    });

    _startImageStream();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final CameraController? cameraController = _controller;

    if (cameraController != null && cameraController.value.isInitialized) {
      cameraController.dispose();
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      _startImageStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final CameraController? cameraController = _controller;
    return Stack(
      alignment: Alignment.center,
      children: [
        if (cameraController != null &&
            cameraController.value.isInitialized) ...[
          Transform.scale(
            scale: 1.0,
            child: AspectRatio(
              aspectRatio: size.aspectRatio,
              child: OverflowBox(
                alignment: Alignment.center,
                child: SizedBox(
                  width: size.width,
                  height: size.width * cameraController.value.aspectRatio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      _cameraDisplayWidget(),
                      if (_detectedFace != null) ...[
                        SizedBox(
                            width: cameraController.value.previewSize!.width,
                            height: cameraController.value.previewSize!.height,
                            child: CustomPaint(
                              painter: FacePainter(
                                  face: _detectedFace!.face,
                                  imageSize: MediaQuery.of(context).size.width >
                                          800
                                      ? Size(
                                          _controller!.value.previewSize!.width,
                                          _controller!
                                              .value.previewSize!.height,
                                        )
                                      : Size(
                                          _controller!
                                              .value.previewSize!.height,
                                          _controller!.value.previewSize!.width,
                                        )),
                            ))
                      ]
                    ],
                  ),
                ),
              ),
            ),
          )
        ] else ...[
          const Text('No Camera Detected',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w500,
              )),
          CustomPaint(
            size: size,
            painter: HolePainter(),
          )
        ],
        if (widget.showControls) ...[
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showCameraLensControl) ...[_lensControlWidget()],
                ],
              ),
            ),
          )
        ],
        Positioned(
            left: 15,
            top: 15,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                Navigator.pop(context);
              },
            ))
      ],
    );
  }

  /// Render camera.
  Widget _cameraDisplayWidget() {
    final CameraController? cameraController = _controller;
    if (cameraController != null && cameraController.value.isInitialized) {
      return CameraPreview(cameraController, child: Builder(builder: (context) {
        if (widget.messageBuilder != null) {
          return widget.messageBuilder!.call(context, _detectedFace);
        }
        if (widget.message != null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 15),
            child: Text(widget.message!,
                textAlign: TextAlign.center, style: widget.messageStyle),
          );
        }
        return const SizedBox.shrink();
      }));
    }
    return const SizedBox.shrink();
  }

  /// Display the control buttons to switch between camera lens.
  Widget _lensControlWidget() {
    final CameraController? cameraController = _controller;

    return IconButton(
        iconSize: 38,
        icon: widget.lensControlIcon ??
            const CircleAvatar(
                radius: 38,
                child: Padding(
                  padding: EdgeInsets.all(2.0),
                  child: Icon(Icons.switch_camera_sharp, size: 25),
                )),
        onPressed:
            cameraController != null && cameraController.value.isInitialized
                ? () {
                    _currentCameraLens =
                        (_currentCameraLens + 1) % _avaliableCameraLens.length;
                    _initCamera();
                  }
                : null);
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (_controller == null) {
      return;
    }

    final CameraController cameraController = _controller!;

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    cameraController.setExposurePoint(offset);
    cameraController.setFocusPoint(offset);
  }

  Future<XFile?> takePicture() async {
    assert(_controller != null, 'Camera controller not initialized');
    if (_controller!.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }
    try {
      XFile file = await _controller!.takePicture();
      return file;
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }

  void _startImageStream() {
    if (_controller != null) {
      _controller!.startImageStream(_processImage);
    }
  }

  void _processImage(CameraImage cameraImage) async {
    if (!_alreadyCheckingImage && mounted) {
      _alreadyCheckingImage = true;
      try {
        final result = await FaceIdentifier.scanImage(
            cameraImage: cameraImage, camera: _controller!.description);

        setState(() => _detectedFace = result);

        if (result != null) {
          try {
            if (result.wellPositioned) {
              await _controller!.stopImageStream();
              // await Future.delayed(const Duration(milliseconds: 500));
              XFile? file = await takePicture();
              await widget.onCapture(File(file!.path), _detectedFace?.face);
              _startImageStream();
            }
          } catch (e) {
            logError(e.toString());
          }
        }
        _alreadyCheckingImage = false;
      } catch (ex, stack) {
        logError('$ex, $stack');
      }
    }
  }
}
