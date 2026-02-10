import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';

import '../../face_camera.dart';
import '../handlers/enum_handler.dart';
import '../handlers/face_identifier.dart';
import '../utils/logger.dart';
import 'face_camera_state.dart';

/// The controller for the [SmartFaceCamera] widget.
class FaceCameraController extends ValueNotifier<FaceCameraState> {
  /// Construct a new [FaceCameraController] instance.
  FaceCameraController({
    this.imageResolution = ImageResolution.medium,
    this.defaultCameraLens,
    this.defaultFlashMode = CameraFlashMode.auto,
    this.enableAudio = true,
    this.autoCapture = false,
    this.ignoreFacePositioning = false,
    this.orientation = CameraOrientation.portraitUp,
    this.performanceMode = FaceDetectorMode.fast,
    this.captureDelay = 3,
    this.showDebugLandmarks = false,
    required this.onCapture,
    this.onFaceDetected,
  })  : assert(captureDelay >= 0, 'captureDelay must be non-negative'),
        super(FaceCameraState.uninitialized());

  /// The desired resolution for the camera.
  final ImageResolution imageResolution;

  /// Use this to set initial camera lens direction.
  final CameraLens? defaultCameraLens;

  /// Use this to set initial flash mode.
  final CameraFlashMode defaultFlashMode;

  /// Set false to disable capture sound.
  final bool enableAudio;

  /// Set true to capture image on face detected.
  final bool autoCapture;

  /// Set true to trigger onCapture even when the face is not well positioned
  final bool ignoreFacePositioning;

  /// Use this to lock camera orientation.
  final CameraOrientation? orientation;

  /// Use this to set your preferred performance mode.
  final FaceDetectorMode performanceMode;

  /// Countdown delay in seconds before auto-capture when face is well-positioned.
  /// Only applies when autoCapture is true. Default is 3 seconds.
  /// Set to 0 to capture immediately without countdown.
  final int captureDelay;

  /// Set true to show debug markers for facial landmarks (eyes, nose, mouth, etc.)
  final bool showDebugLandmarks;

  Timer? _countdownTimer;
  int _currentCountdown = 0;

  /// Callback invoked when camera captures image.
  final void Function(File? image) onCapture;

  /// Callback invoked when camera detects face.
  final void Function(Face? face)? onFaceDetected;

  /// Gets all available camera lens and set current len
  void _getAllAvailableCameraLens() {
    int currentCameraLens = 0;
    final List<CameraLens> availableCameraLens = [];
    for (CameraDescription d in FaceCamera.cameras) {
      final lens = EnumHandler.cameraLensDirectionToCameraLens(d.lensDirection);
      if (lens != null && !availableCameraLens.contains(lens)) {
        availableCameraLens.add(lens);
      }
    }

    if (defaultCameraLens != null) {
      try {
        currentCameraLens = availableCameraLens.indexOf(defaultCameraLens!);
      } catch (e) {
        logError(e.toString());
      }
    }

    value = value.copyWith(
        availableCameraLens: availableCameraLens,
        currentCameraLens: currentCameraLens);
  }

  Future<void> _initCamera() async {
    final cameras = FaceCamera.cameras
        .where((c) =>
            c.lensDirection ==
            EnumHandler.cameraLensToCameraLensDirection(
                value.availableCameraLens[value.currentCameraLens]))
        .toList();

    if (cameras.isNotEmpty) {
      final cameraController = CameraController(cameras.first,
          EnumHandler.imageResolutionToResolutionPreset(imageResolution),
          enableAudio: enableAudio,
          imageFormatGroup: Platform.isAndroid
              ? ImageFormatGroup.nv21
              : ImageFormatGroup.bgra8888);

      await cameraController.initialize().whenComplete(() {
        value = value.copyWith(
            isInitialized: true, cameraController: cameraController);
      });

      await changeFlashMode(value.availableFlashMode.indexOf(defaultFlashMode));

      await cameraController.lockCaptureOrientation(
          EnumHandler.cameraOrientationToDeviceOrientation(orientation));
    }

    startImageStream();
  }

  Future<void> changeFlashMode([int? index]) async {
    final newIndex =
        index ?? (value.currentFlashMode + 1) % value.availableFlashMode.length;
    await value.cameraController!
        .setFlashMode(EnumHandler.cameraFlashModeToFlashMode(
            value.availableFlashMode[newIndex]))
        .then((_) {
      value = value.copyWith(currentFlashMode: newIndex);
    });
  }

  /// The supplied [zoom] value should be between 1.0 and the maximum supported
  Future<void> setZoomLevel(double zoom) async {
    final CameraController? cameraController = value.cameraController;
    if (cameraController == null) {
      return;
    }
    await cameraController.setZoomLevel(zoom);
  }

  Future<void> changeCameraLens() async {
    value = value.copyWith(
        currentCameraLens:
            (value.currentCameraLens + 1) % value.availableCameraLens.length);
    _initCamera();
  }

  Future<XFile?> takePicture() async {
    final CameraController? cameraController = value.cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      logError('Error: select a camera first.');
      return null;
    }

    if (cameraController.value.isTakingPicture) {
      logError('A capture is already pending');
      return null;
    }

    try {
      XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
  }

  Future<void> startImageStream() async {
    final CameraController? cameraController = value.cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    // Clear capturing flag when starting/restarting image stream
    value = value.copyWith(isCapturing: false);
    if (!cameraController.value.isStreamingImages) {
      await cameraController.startImageStream(_processImage);
    }
  }

  Future<void> stopImageStream() async {
    final CameraController? cameraController = value.cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (cameraController.value.isStreamingImages) {
      await cameraController.stopImageStream();
    }
  }

  void _processImage(CameraImage cameraImage) async {
    final CameraController? cameraController = value.cameraController;
    if (!value.alreadyCheckingImage) {
      value = value.copyWith(alreadyCheckingImage: true);
      try {
        await FaceIdentifier.scanImage(
                cameraImage: cameraImage,
                controller: cameraController,
                performanceMode: performanceMode)
            .then((result) async {
          value = value.copyWith(detectedFace: result);

          if (result != null) {
            try {
              if (result.face != null) {
                onFaceDetected?.call(result.face);
              }

              // Check if face landmarks are centered in frame
              // Note: Image dimensions are swapped for portrait orientation
              bool isFaceCentered = result.face != null &&
                  _isFaceCentered(
                      result.face!,
                      Size(cameraImage.height.toDouble(),
                          cameraImage.width.toDouble()));

              // Update state with positioning status
              value = value.copyWith(isFaceWellPositioned: isFaceCentered);

              // Require face to be detected, then check positioning (unless ignored)
              bool shouldCapture = result.face != null &&
                  (isFaceCentered || ignoreFacePositioning);

              // Don't start countdown if already capturing
              if (autoCapture && shouldCapture && !value.isCapturing) {
                _startCountdown();
              } else if (value.isCapturing) {
                // If capturing, make sure countdown is cancelled
                _cancelCountdown();
              } else {
                _cancelCountdown();
              }
            } catch (e) {
              logError(e.toString());
            }
          } else {
            // No face detected - update state and cancel countdown
            value = value.copyWith(isFaceWellPositioned: false);
            _cancelCountdown();
          }
        });
        value = value.copyWith(alreadyCheckingImage: false);
      } catch (ex, stack) {
        value = value.copyWith(alreadyCheckingImage: false);
        logError('$ex, $stack');
      }
    }
  }

  void _startCountdown() {
    // If countdown is 0, capture immediately
    if (captureDelay == 0) {
      captureImage();
      return;
    }

    // If countdown already running, do nothing
    if (_countdownTimer != null && _countdownTimer!.isActive) {
      return;
    }

    // Start new countdown
    _currentCountdown = captureDelay;
    value = value.copyWith(countdown: _currentCountdown);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Check if face is still detected and well-positioned
      final detectedFace = value.detectedFace;
      if (detectedFace == null ||
          detectedFace.face == null ||
          !value.isFaceWellPositioned) {
        // Face moved or disappeared - cancel countdown
        timer.cancel();
        value = value.copyWith(countdown: null);
        _currentCountdown = 0;
        return;
      }

      _currentCountdown--;
      if (_currentCountdown <= 0) {
        timer.cancel();
        value = value.copyWith(countdown: null);
        captureImage();
      } else {
        value = value.copyWith(countdown: _currentCountdown);
      }
    });
  }

  void _cancelCountdown() {
    if (_countdownTimer != null && _countdownTimer!.isActive) {
      _countdownTimer!.cancel();
      _currentCountdown = 0;
      value = value.copyWith(countdown: null);
    }
  }

  /// Get guidance for positioning the face in the fixed frame
  /// Returns a message like "Move closer", "Move left", etc.
  /// Returns null only when face is perfectly positioned (triggers countdown)
  String? getFacePositionGuidance() {
    final detectedFace = value.detectedFace;
    if (detectedFace?.face == null) {
      return "Place your face in the frame";
    }

    final face = detectedFace!.face!;
    final cameraController = value.cameraController;
    if (cameraController == null) return "Place your face in the frame";

    final imageSize = Size(
      cameraController.value.previewSize!.height,
      cameraController.value.previewSize!.width,
    );

    // If already centered, no guidance needed (countdown will start)
    if (_isFaceCentered(face, imageSize)) {
      return null;
    }

    // Check face distance by measuring eye separation
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    if (leftEye != null && rightEye != null) {
      final leftEyeX = leftEye.position.x / imageSize.width;
      final leftEyeY = leftEye.position.y / imageSize.height;
      final rightEyeX = rightEye.position.x / imageSize.width;
      final rightEyeY = rightEye.position.y / imageSize.height;

      // Calculate actual Euclidean distance (not squared)
      final dx = leftEyeX - rightEyeX;
      final dy = leftEyeY - rightEyeY;
      final eyeDistance = sqrt(dx * dx + dy * dy);

      // If eyes are too close (distance < 0.14), face is too far
      if (eyeDistance < 0.14) {
        return "Move closer";
      }

      // If eyes are too far apart (distance > 0.28), face is too close
      if (eyeDistance > 0.28) {
        return "Move back";
      }
    }

    // Calculate face metrics
    final frameSize = 0.7;
    final frameCenterX = 0.5;
    final frameCenterY = 0.5;

    var faceLeft = (face.boundingBox.left / imageSize.width).clamp(0.0, 1.0);
    var faceRight = (face.boundingBox.right / imageSize.width).clamp(0.0, 1.0);
    var faceTop = (face.boundingBox.top / imageSize.height).clamp(0.0, 1.0);
    var faceBottom = (face.boundingBox.bottom / imageSize.height).clamp(0.0, 1.0);

    final faceWidth = faceRight - faceLeft;
    final faceCenterX = (faceLeft + faceRight) / 2;
    final faceCenterY = (faceTop + faceBottom) / 2;

    // Priority 1: Distance (face too small or too large)
    // If face is very small (width < 50% of frame), need to get closer
    if (faceWidth < frameSize * 0.5) {
      return "Move closer";
    }

    // If face is too large (width > 95% of frame), need to move back
    if (faceWidth > frameSize * 0.95) {
      return "Move back";
    }

    // Priority 2: Centering (if face is reasonable size but not centered)
    final centerOffsetX = faceCenterX - frameCenterX;
    final centerOffsetY = faceCenterY - frameCenterY;

    // Horizontal guidance (use threshold slightly less than strict requirement of 18%)
    if (centerOffsetX.abs() > 0.15) {
      // For front camera (mirrored display):
      // If faceCenterX < frameCenterX (left side), user should move right
      // If faceCenterX > frameCenterX (right side), user should move left
      if (centerOffsetX < 0) {
        return "Move right";
      } else {
        return "Move left";
      }
    }

    // Vertical guidance
    if (centerOffsetY.abs() > 0.15) {
      if (centerOffsetY < 0) {
        return "Move down";
      } else {
        return "Move up";
      }
    }

    // If we get here, face is good size and reasonably centered,
    // but not meeting the strict requirements yet
    return "Center your face";
  }

  /// Check if face is well-positioned in the fixed frame
  /// Returns true ONLY if ALL required facial landmarks are inside the frame
  /// AND the nose is near the center AND the face is close enough
  bool _isFaceCentered(Face face, Size imageSize) {
    // Define the fixed frame size (70% of screen, centered)
    final frameSize = 0.7;
    final frameCenterX = 0.5;
    final frameCenterY = 0.5;

    // Calculate fixed frame bounds (normalized 0-1)
    final frameLeft = frameCenterX - (frameSize / 2);   // 0.15
    final frameRight = frameCenterX + (frameSize / 2);  // 0.85
    final frameTop = frameCenterY - (frameSize / 2);    // 0.15
    final frameBottom = frameCenterY + (frameSize / 2); // 0.85

    // First check: Face must be at correct distance (eyes not too close or too far)
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    if (leftEye != null && rightEye != null) {
      final leftEyeX = leftEye.position.x / imageSize.width;
      final leftEyeY = leftEye.position.y / imageSize.height;
      final rightEyeX = rightEye.position.x / imageSize.width;
      final rightEyeY = rightEye.position.y / imageSize.height;

      // Calculate actual Euclidean distance (not squared)
      final dx = leftEyeX - rightEyeX;
      final dy = leftEyeY - rightEyeY;
      final eyeDistance = sqrt(dx * dx + dy * dy);

      // Face must be at correct distance (0.14 to 0.28)
      if (eyeDistance < 0.14 || eyeDistance > 0.28) {
        return false;
      }
    }

    // Check that ALL required landmarks are within the frame
    final requiredLandmarks = [
      FaceLandmarkType.leftEye,
      FaceLandmarkType.rightEye,
      FaceLandmarkType.noseBase,
      FaceLandmarkType.bottomMouth,
      FaceLandmarkType.leftMouth,
      FaceLandmarkType.rightMouth,
    ];

    for (final landmarkType in requiredLandmarks) {
      final landmark = face.landmarks[landmarkType];
      if (landmark == null) {
        return false; // Required landmark not detected
      }

      // Convert landmark position to normalized coordinates (0-1)
      final x = (landmark.position.x / imageSize.width).clamp(0.0, 1.0);
      final y = (landmark.position.y / imageSize.height).clamp(0.0, 1.0);

      // Check if landmark is within frame bounds
      if (x < frameLeft || x > frameRight || y < frameTop || y > frameBottom) {
        return false; // Landmark is outside frame
      }
    }

    // Additional check: Nose must be near center (within 20% tolerance)
    final noseLandmark = face.landmarks[FaceLandmarkType.noseBase];
    if (noseLandmark != null) {
      final noseX = (noseLandmark.position.x / imageSize.width).clamp(0.0, 1.0);
      final noseY = (noseLandmark.position.y / imageSize.height).clamp(0.0, 1.0);

      // Check if nose is within 20% of center (0.4 to 0.6 range)
      final centerTolerance = 0.2;
      if (noseX < (frameCenterX - centerTolerance) ||
          noseX > (frameCenterX + centerTolerance) ||
          noseY < (frameCenterY - centerTolerance) ||
          noseY > (frameCenterY + centerTolerance)) {
        return false; // Nose is not near center
      }
    }

    // Check head rotation (must be facing forward)
    if (face.headEulerAngleY != null &&
        (face.headEulerAngleY! > 12 || face.headEulerAngleY! < -12)) {
      return false; // Head rotated left/right
    }
    if (face.headEulerAngleZ != null &&
        (face.headEulerAngleZ! > 12 || face.headEulerAngleZ! < -12)) {
      return false; // Head tilted sideways
    }

    return true; // All checks passed
  }

  @Deprecated('Use [captureImage]')
  void onTakePictureButtonPressed() async {
    captureImage();
  }

  void captureImage() async {
    final CameraController? cameraController = value.cameraController;
    try {
      // Set capturing flag to prevent countdown from starting again
      value = value.copyWith(isCapturing: true);

      cameraController!.stopImageStream().whenComplete(() async {
        await Future.delayed(const Duration(milliseconds: 500));
        takePicture().then((XFile? file) {
          /// Return image callback
          if (file != null) {
            onCapture.call(File(file.path));
          }
        });
      });
    } catch (e) {
      logError(e.toString());
    }
  }

/*  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (value.cameraController == null) {
      return;
    }

    final CameraController cameraController = value.cameraController!;

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    cameraController.setExposurePoint(offset);
    cameraController.setFocusPoint(offset);
  }*/

  Future<void> initialize() async {
    _getAllAvailableCameraLens();
    _initCamera();
  }

  /// Enables controls only when camera is initialized.
  bool get enableControls {
    final CameraController? cameraController = value.cameraController;
    return cameraController != null && cameraController.value.isInitialized;
  }

  /// Dispose the controller.
  ///
  /// Once the controller is disposed, it cannot be used anymore.
  @override
  Future<void> dispose() async {
    _cancelCountdown();
    final CameraController? cameraController = value.cameraController;

    if (cameraController != null && cameraController.value.isInitialized) {
      cameraController.dispose();
    }
    super.dispose();
  }
}
