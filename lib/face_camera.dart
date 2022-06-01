import 'dart:async';

import 'package:camera/camera.dart';

import 'src/utils/logger.dart';

export 'package:face_camera/src/smart_face_camera.dart';
export 'package:face_camera/src/res/emums.dart';

class FaceCamera {
  //static const MethodChannel _channel = MethodChannel('face_camera');

  static late List<CameraDescription> _cameras = [];

  /// Initialize device cameras
  static Future<void> intialize() async {
    /// Fetch the available cameras before initializing the app.
    try {
      _cameras = await availableCameras();
    } on CameraException catch (e) {
      logError(e.code, e.description);
    }
  }

  /// Returns available cameras
  static List<CameraDescription> get cameras {
    return _cameras;
  }
}
