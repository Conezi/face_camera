import 'package:camera/camera.dart';

import '../../face_camera.dart';

/// This class represents the current state of a [FaceCameraController].
class FaceCameraState {
  /// Create a new [FaceCameraState] instance.
  const FaceCameraState({
    required this.currentCameraLens,
    required this.currentFlashMode,
    required this.isInitialized,
    required this.availableCameraLens,
    required this.availableFlashMode,
    required this.alreadyCheckingImage,
    this.cameraController,
    this.detectedFace,
  });

  /// Create a new [FaceCameraState] instance that is uninitialized.
  FaceCameraState.uninitialized()
      : this(
          availableCameraLens: [],
          currentCameraLens: 0,
          currentFlashMode: 0,
          isInitialized: false,
          alreadyCheckingImage: false,
          cameraController: null,
          detectedFace: null,
          availableFlashMode: [
            CameraFlashMode.off,
            CameraFlashMode.auto,
            CameraFlashMode.always
          ],
        );

  /// Camera dependency controller
  final CameraController? cameraController;

  /// The available cameras.
  ///
  /// This is null if no camera is found.
  final List<CameraLens> availableCameraLens;

  /// The current camera lens in use.
  ///
  /// Default value is 0.
  final int currentCameraLens;

  /// The current flash mode in use.
  ///
  /// Default value is 0.
  final int currentFlashMode;

  /// Whether the face camera has initialized successfully.
  ///
  /// This is `true` if the camera is ready to be used.
  final bool isInitialized;

  final List<CameraFlashMode> availableFlashMode;

  final bool alreadyCheckingImage;

  final DetectedFace? detectedFace;

  /// Create a copy of this state with the given parameters.
  FaceCameraState copyWith({
    List<CameraLens>? availableCameraLens,
    int? currentCameraLens,
    int? currentFlashMode,
    CameraFlashMode? flashMode,
    bool? isInitialized,
    bool? isRunning,
    bool? alreadyCheckingImage,
    double? zoomScale,
    CameraController? cameraController,
    List<CameraFlashMode>? availableFlashMode,
    DetectedFace? detectedFace,
  }) {
    return FaceCameraState(
      availableCameraLens: availableCameraLens ?? this.availableCameraLens,
      currentCameraLens: currentCameraLens ?? this.currentCameraLens,
      currentFlashMode: currentFlashMode ?? this.currentFlashMode,
      isInitialized: isInitialized ?? this.isInitialized,
      alreadyCheckingImage: alreadyCheckingImage ?? this.alreadyCheckingImage,
      cameraController: cameraController ?? this.cameraController,
      availableFlashMode: availableFlashMode ?? this.availableFlashMode,
      detectedFace: detectedFace ?? this.detectedFace,
    );
  }
}
