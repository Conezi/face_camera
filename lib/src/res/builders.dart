
import 'package:flutter/material.dart';

import '../../face_camera.dart';

/// Returns widget for flash modes
typedef FlashControlBuilder = Widget Function(
    BuildContext context, CameraFlashMode mode);