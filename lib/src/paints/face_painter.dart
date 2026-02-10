import 'package:flutter/material.dart';

import '../../face_camera.dart';
import '../res/app_images.dart';

class FacePainter extends CustomPainter {
  FacePainter(
      {required this.imageSize,
      this.face,
      required this.indicatorShape,
      this.indicatorAssetImage,
      this.isFaceWellPositioned = false,
      this.showDebugLandmarks = false});
  final Size imageSize;
  double? scaleX, scaleY;
  final Face? face;
  final IndicatorShape indicatorShape;
  final String? indicatorAssetImage;
  final bool isFaceWellPositioned;
  final bool showDebugLandmarks;
  @override
  void paint(Canvas canvas, Size size) {
    scaleX = size.width / imageSize.width;
    scaleY = size.height / imageSize.height;

    // Handle fixedFrame mode separately
    if (indicatorShape == IndicatorShape.fixedFrame) {
      _drawFixedFrame(canvas, size);
      // Don't return early - continue to draw debug landmarks if enabled
      if (showDebugLandmarks && face != null) {
        _drawDebugLandmarks(canvas, size);
      }
      return;
    }

    if (face == null) return;

    Paint paint;

    if (face!.headEulerAngleY! > 10 || face!.headEulerAngleY! < -10) {
      paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = Colors.red;
    } else {
      paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = Colors.green;
    }

    switch (indicatorShape) {
      case IndicatorShape.defaultShape:
        canvas.drawPath(
          _defaultPath(
              rect: face!.boundingBox,
              widgetSize: size,
              scaleX: scaleX,
              scaleY: scaleY),
          paint, // Adjust color as needed
        );
        break;
      case IndicatorShape.square:
        canvas.drawRRect(
            _scaleRect(
                rect: face!.boundingBox,
                widgetSize: size,
                scaleX: scaleX,
                scaleY: scaleY),
            paint);
        break;
      case IndicatorShape.circle:
        canvas.drawCircle(
          _circleOffset(
              rect: face!.boundingBox,
              widgetSize: size,
              scaleX: scaleX,
              scaleY: scaleY),
          face!.boundingBox.width / 2 * scaleX!,
          paint, // Adjust color as needed
        );
        break;
      case IndicatorShape.triangle:
      case IndicatorShape.triangleInverted:
        canvas.drawPath(
          _trianglePath(
              rect: face!.boundingBox,
              widgetSize: size,
              scaleX: scaleX,
              scaleY: scaleY,
              isInverted: indicatorShape == IndicatorShape.triangleInverted),
          paint, // Adjust color as needed
        );
        break;
      case IndicatorShape.image:
        final AssetImage image =
            AssetImage(indicatorAssetImage ?? AppImages.faceNet);
        final ImageStream imageStream = image.resolve(ImageConfiguration.empty);

        imageStream.addListener(
            ImageStreamListener((ImageInfo imageInfo, bool synchronousCall) {
          final rect = face!.boundingBox;
          final Rect destinationRect = Rect.fromPoints(
            Offset(size.width - rect.left.toDouble() * scaleX!,
                rect.top.toDouble() * scaleY!),
            Offset(size.width - rect.right.toDouble() * scaleX!,
                rect.bottom.toDouble() * scaleY!),
          );

          canvas.drawImageRect(
            imageInfo.image,
            Rect.fromLTRB(0, 0, imageInfo.image.width.toDouble(),
                imageInfo.image.height.toDouble()),
            destinationRect,
            Paint(),
          );
        }));
        break;
      case IndicatorShape.fixedFrame:
        // Handled at the beginning of paint() method
        break;
      case IndicatorShape.none:
        break;
    }

    // Draw debug landmarks if enabled
    if (showDebugLandmarks && face != null) {
      _drawDebugLandmarks(canvas, size);
    }
  }

  /// Draw debug markers for facial landmarks
  void _drawDebugLandmarks(Canvas canvas, Size size) {
    if (face == null || scaleX == null || scaleY == null) return;

    final landmarkPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;

    // Draw each landmark with different colors
    final landmarks = <FaceLandmarkType, Color>{
      FaceLandmarkType.leftEye: Colors.blue,
      FaceLandmarkType.rightEye: Colors.blue,
      FaceLandmarkType.noseBase: Colors.green,
      FaceLandmarkType.bottomMouth: Colors.red,
      FaceLandmarkType.leftMouth: Colors.red,
      FaceLandmarkType.rightMouth: Colors.red,
      FaceLandmarkType.leftCheek: Colors.yellow,
      FaceLandmarkType.rightCheek: Colors.yellow,
      FaceLandmarkType.leftEar: Colors.purple,
      FaceLandmarkType.rightEar: Colors.purple,
    };

    for (final entry in landmarks.entries) {
      final landmark = face!.landmarks[entry.key];
      if (landmark != null) {
        landmarkPaint.color = entry.value;

        // Convert landmark position to screen coordinates
        final x = size.width - landmark.position.x.toDouble() * scaleX!;
        final y = landmark.position.y.toDouble() * scaleY!;

        // Draw landmark as a circle
        canvas.drawCircle(Offset(x, y), 6.0, landmarkPaint);

        // Draw white border for visibility
        final borderPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = Colors.white;
        canvas.drawCircle(Offset(x, y), 6.0, borderPaint);
      }
    }

    // Draw face bounding box in debug mode (clamped to image bounds)
    final boundingBoxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.cyan;

    // Clamp bounding box to valid image range (ML Kit can extend beyond image)
    final clampedLeft = face!.boundingBox.left.clamp(0.0, imageSize.width);
    final clampedRight = face!.boundingBox.right.clamp(0.0, imageSize.width);
    final clampedTop = face!.boundingBox.top.clamp(0.0, imageSize.height);
    final clampedBottom = face!.boundingBox.bottom.clamp(0.0, imageSize.height);

    canvas.drawRect(
      Rect.fromLTRB(
        size.width - clampedLeft * scaleX!,
        clampedTop * scaleY!,
        size.width - clampedRight * scaleX!,
        clampedBottom * scaleY!,
      ),
      boundingBoxPaint,
    );
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate.imageSize != imageSize ||
           oldDelegate.face != face ||
           oldDelegate.showDebugLandmarks != showDebugLandmarks ||
           oldDelegate.isFaceWellPositioned != isFaceWellPositioned;
  }

  /// Draw a fixed centered frame that changes color based on face position
  void _drawFixedFrame(Canvas canvas, Size size) {
    // Define fixed square in center of screen (70% of screen width)
    final double squareSize = size.width * 0.7;
    final Rect fixedRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: squareSize,
      height: squareSize,
    );

    // Determine color based on face positioning
    Paint paint;
    if (face == null) {
      // No face detected - white/gray
      paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = Colors.white.withOpacity(0.5);
    } else if (isFaceWellPositioned) {
      // Face is properly positioned - green
      paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = Colors.green;
    } else {
      // Face detected but not positioned correctly - red
      paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = Colors.red;
    }

    // Draw fixed rounded square
    canvas.drawRRect(
      RRect.fromRectAndRadius(fixedRect, const Radius.circular(10)),
      paint,
    );
  }
}

Path _defaultPath(
    {required Rect rect,
    required Size widgetSize,
    double? scaleX,
    double? scaleY}) {
  double cornerExtension =
      30.0; // Adjust the length of the corner extensions as needed

  double left = widgetSize.width - rect.left.toDouble() * scaleX!;
  double right = widgetSize.width - rect.right.toDouble() * scaleX;
  double top = rect.top.toDouble() * scaleY!;
  double bottom = rect.bottom.toDouble() * scaleY;
  return Path()
    ..moveTo(left - cornerExtension, top)
    ..lineTo(left, top)
    ..lineTo(left, top + cornerExtension)
    ..moveTo(right + cornerExtension, top)
    ..lineTo(right, top)
    ..lineTo(right, top + cornerExtension)
    ..moveTo(left - cornerExtension, bottom)
    ..lineTo(left, bottom)
    ..lineTo(left, bottom - cornerExtension)
    ..moveTo(right + cornerExtension, bottom)
    ..lineTo(right, bottom)
    ..lineTo(right, bottom - cornerExtension);
}

RRect _scaleRect(
    {required Rect rect,
    required Size widgetSize,
    double? scaleX,
    double? scaleY}) {
  return RRect.fromLTRBR(
      (widgetSize.width - rect.left.toDouble() * scaleX!),
      rect.top.toDouble() * scaleY!,
      widgetSize.width - rect.right.toDouble() * scaleX,
      rect.bottom.toDouble() * scaleY,
      const Radius.circular(10));
}

Offset _circleOffset(
    {required Rect rect,
    required Size widgetSize,
    double? scaleX,
    double? scaleY}) {
  return Offset(
    (widgetSize.width - rect.center.dx * scaleX!),
    rect.center.dy * scaleY!,
  );
}

Path _trianglePath(
    {required Rect rect,
    required Size widgetSize,
    double? scaleX,
    double? scaleY,
    bool isInverted = false}) {
  if (isInverted) {
    return Path()
      ..moveTo(widgetSize.width - rect.center.dx * scaleX!,
          rect.bottom.toDouble() * scaleY!)
      ..lineTo(widgetSize.width - rect.left.toDouble() * scaleX,
          rect.top.toDouble() * scaleY)
      ..lineTo(widgetSize.width - rect.right.toDouble() * scaleX,
          rect.top.toDouble() * scaleY)
      ..close();
  }
  return Path()
    ..moveTo(widgetSize.width - rect.center.dx * scaleX!,
        rect.top.toDouble() * scaleY!)
    ..lineTo(widgetSize.width - rect.left.toDouble() * scaleX,
        rect.bottom.toDouble() * scaleY)
    ..lineTo(widgetSize.width - rect.right.toDouble() * scaleX,
        rect.bottom.toDouble() * scaleY)
    ..close();
}
