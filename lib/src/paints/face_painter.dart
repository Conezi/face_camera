import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;

class FacePainter extends CustomPainter {
  final LottieDrawable drawable;
  FacePainter(
      {required this.imageSize,
      required LottieComposition composition,
      this.face})
      : drawable = LottieDrawable(composition);

  final Size imageSize;
  double? scaleX, scaleY;
  Face? face;

  @override
  void paint(Canvas canvas, Size size) {
    if (face == null) return;
    // print(face!.headEulerAngleY);
    // when the head is closer to the center increase the progress
    // when the head is further away decrease the progress
    // drawable.progress = 1 - (face!.headEulerAngleY.abs() / 90);
    final double progressY = 1 - (face!.headEulerAngleY!.abs() / 90); // 0 - 1
    final double progressX = 1 - (face!.headEulerAngleX!.abs() / 90); // 0 - 1
    final double progress = math.exp(progressX + progressY * 3) / 50;
    // print(progress);
    drawable.setProgress(progress > 1 ? 1 : progress);

    scaleX = size.width / imageSize.width;
    scaleY = size.height / imageSize.height;

    final rect = Rect.fromLTRB(
        face!.boundingBox.left.toDouble() * scaleX! * 0.9,
        face!.boundingBox.top * scaleY! * 0.9,
        face!.boundingBox.right * scaleX! * 1.1,
        face!.boundingBox.bottom * scaleY! * 1.1);

    drawable.draw(canvas, rect);

    // canvas.drawRRect(
    //     _scaleRect(
    //         rect: face!.boundingBox,
    //         imageSize: imageSize,
    //         widgetSize: size,
    //         scaleX: scaleX!,
    //         scaleY: scaleY!),
    //     paint);
  }
  // @override
  // void paint(Canvas canvas, Size size) {
  //   var frameCount = 40;
  //   var columns = 10;
  //   // for (var i = 0; i < frameCount; i++) {
  //   //   var destRect = Offset(i % columns * 50.0, i ~/ 10 * 80.0) & (size / 5);
  //   //   drawable
  //   //     ..setProgress(i / frameCount)
  //   //     ..draw(canvas, destRect);
  //   // }
  // }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return true;
    // return oldDelegate.imageSize != imageSize || oldDelegate.face != face;
  }
}

RRect _scaleRect(
    {required Rect rect,
    required Size imageSize,
    required Size widgetSize,
    double? scaleX,
    double? scaleY}) {
  return RRect.fromLTRBR(
      rect.left.toDouble() * scaleX!,
      rect.top.toDouble() * scaleY!,
      rect.right.toDouble() * scaleX,
      rect.bottom.toDouble() * scaleY,
      const Radius.circular(10));
}
