
import 'dart:async';

import 'package:camera/camera.dart';

export 'package:face_camera/src/smart_face_camera.dart';
export 'package:face_camera/src/res/emums.dart';

class FaceCamera {

  //static const MethodChannel _channel = MethodChannel('face_camera');


  static late List<CameraDescription> _cameras=[];

  /// Initialize device cameras
  static Future<void> intialize()async{
    /// Get devices cameras
    _cameras = await availableCameras();
  }

  /// Returns available cameras
  static List<CameraDescription> get cameras {
    return _cameras;
  }

}
