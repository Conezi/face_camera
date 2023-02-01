import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

import '../res/enums.dart';

class EnumHandler {
  static ResolutionPreset imageResolutionToResolutionPreset(
      ImageResolution res) {
    switch (res) {
      case ImageResolution.low:
        // TODO: Handle this case.
        return ResolutionPreset.low;
      case ImageResolution.medium:
        // TODO: Handle this case.
        return ResolutionPreset.medium;
      case ImageResolution.high:
        // TODO: Handle this case.
        return ResolutionPreset.high;
      case ImageResolution.veryHigh:
        // TODO: Handle this case.
        return ResolutionPreset.veryHigh;
      case ImageResolution.ultraHigh:
        // TODO: Handle this case.
        return ResolutionPreset.ultraHigh;
      case ImageResolution.max:
        // TODO: Handle this case.
        return ResolutionPreset.max;
    }
  }

  static CameraLensDirection? cameraLensToCameraLensDirection(
      CameraLens? lens) {
    switch (lens) {
      case CameraLens.front:
        // TODO: Handle this case.
        return CameraLensDirection.front;
      case CameraLens.back:
        // TODO: Handle this case.
        return CameraLensDirection.back;
      case CameraLens.external:
        // TODO: Handle this case.
        return CameraLensDirection.external;
      default:
        return null;
    }
  }

  static CameraLens? cameraLensDirectionToCameraLens(
      CameraLensDirection? lens) {
    switch (lens) {
      case CameraLensDirection.front:
        // TODO: Handle this case.
        return CameraLens.front;
      case CameraLensDirection.back:
        // TODO: Handle this case.
        return CameraLens.back;
      case CameraLensDirection.external:
        // TODO: Handle this case.
        return CameraLens.external;
      default:
        return null;
    }
  }

  static FlashMode cameraFlashModeToFlashMode(CameraFlashMode mode) {
    switch (mode) {
      case CameraFlashMode.off:
        // TODO: Handle this case.
        return FlashMode.off;
      case CameraFlashMode.auto:
        // TODO: Handle this case.
        return FlashMode.auto;
      case CameraFlashMode.always:
        // TODO: Handle this case.
        return FlashMode.always;
    }
  }

  static DeviceOrientation? cameraOrientationToDeviceOrientation(
      CameraOrientation? orientation) {
    switch (orientation) {
      case CameraOrientation.portraitUp:
        // TODO: Handle this case.
        return DeviceOrientation.portraitUp;
      case CameraOrientation.landscapeLeft:
        // TODO: Handle this case.
        return DeviceOrientation.landscapeLeft;
      case CameraOrientation.portraitDown:
        // TODO: Handle this case.
        return DeviceOrientation.portraitDown;
      case CameraOrientation.landscapeRight:
        // TODO: Handle this case.
        return DeviceOrientation.landscapeRight;
      default:
        return null;
    }
  }
}
