import 'package:flutter/material.dart';

import '../../face_camera.dart';

/// Returns widget for flash modes
typedef FlashControlBuilder = Widget Function(
    BuildContext context, CameraFlashMode mode);

/// Returns message based on face position
typedef MessageBuilder = Widget Function(
    BuildContext context, DetectedFace? detectedFace);
