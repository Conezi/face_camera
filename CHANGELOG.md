## 0.1.4

- Adds a namespace for compatibility with AGP 8.0.
- Enhanced performance.

## 0.1.3

- Updated dependencies.
- Fixed face detection issue on some Android devices.
- Changed minimum iOS requirement to 15.5.0.
- Added `setZoomLevel` control to the `FaceCameraController`.
- Added `ignoreFacePositioning` allowing developers to trigger `onCapture` even when the face is not well positioned.
- Modified `README.md`.

## 0.1.2

- Updated dependencies.
- Fixed face detection issue on some Android devices.

**DEPRECATIONS**

- The `onTakePictureButtonPressed` have been replaced with `captureImage`.

## 0.1.1

- Added `FaceCameraController` allowing developers to control the `SmartFaceCamera` widget.
- Updated dependencies.
- Enhanced performance.
- Modified `README.md`.

**BREAKING CHANGES:**
- `captureControlIcon` has been replaced with `captureControlBuilder`.
- `imageResolution, defaultCameraLens, defaultFlashMode, enableAudio, autoCapture, orientation, onCapture, onFaceDetected, performanceMode` has been moved to `FaceCameraController`.

## 0.1.0

- Improved codebase documentations.
- Added `performanceMode` allowing developers to choose their preferred performance mode.
- Include `IndicatorShape.none` allowing developers to hide face indicator.

## 0.0.9

- Added `captureControlBuilder` returning detected face so that developers can build a custom capture control icon.
- Added `autoDisableCaptureControl` to disable capture control when enabled and no face is detected.
- Enhanced performance.
- Updated dependencies.
- Modified `README.md`.

**DEPRECATIONS**

- The `captureControlIcon` have been replaced with `captureControlBuilder`.

## 0.0.8

- Added indicatorShapes and indicatorAssetImage parameters so that developers can choose their desired face indicator.
- Added indicatorBuilder returning detected face and image size so that developers can build a custom face indicator.
- Updated dependencies.
- Modified `README.md`.

## 0.0.7

- Fixed Android face detection issue.
- Updated dependencies.
- Modified `README.md`.

## 0.0.6

- Added onFaceDetected callback.
- Updates code for stricter lint checks.
- Updated dependencies.
- Modified `README.md`.


## 0.0.5

- Bug fix.
- Modified `README.md`.


## 0.0.4

- Updated dependencies.
- Added message builder returning detected face so developers can return message based on face position.


## 0.0.3

- Bug fix.
- Modified `pubspec.yaml` description.


## 0.0.2

- Fixed camera lens control.


## 0.0.1

- Initial release.