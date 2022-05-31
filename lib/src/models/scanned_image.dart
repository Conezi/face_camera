import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class ScannedImage{
  final Face detectedFace;
  final bool wellPositioned;
  const ScannedImage({
    required this.detectedFace,
    required this.wellPositioned});

  ScannedImage copyWith({
    Face? detectedFace,
    bool? wellPositioned
  })=>ScannedImage(
      detectedFace: detectedFace ?? this.detectedFace,
      wellPositioned: wellPositioned ?? this.wellPositioned
  );

}