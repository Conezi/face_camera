# face_camera

#### A Flutter camera plugin that detects face in real-time.

### Preview
---  

![](https://github.com/Conezi/face_camera/blob/main/demo/preview.gif?raw=true)


### Installation
---  

First, add `face_camera` as a dependency in your pubspec.yaml file.

```yaml
face_camera: ^<latest-version>
```

### iOS
---  

* Minimum iOS Deployment Target: 15.5.0
* Follow this <a href="https://github.com/bharat-biradar/Google-Ml-Kit-plugin#requirements">link</a> and setup  `ML Kit` this is required for `face_camera` to function properly on `iOS`

Add two rows to the `ios/Runner/Info.plist:`
* one with the key `Privacy - Camera Usage Description` and a usage description.
* and one with the key `Privacy - Microphone Usage Description` and a usage description.

If editing `Info.plist` as text, add:

```
<key>NSCameraUsageDescription</key>
<string>your usage description here</string>
<key>NSMicrophoneUsageDescription</key>
<string>your usage description here</string>
```


### Android
---  

* Change the minimum Android sdk version to 21 (or higher) in your `android/app/build.gradle` file.

```groovy
minSdkVersion 21
```


### Usage
---  

* The first step is to initialize `face_camera` in `main.dart`
```dart
void main() async{
  WidgetsFlutterBinding.ensureInitialized(); //Add this

  await FaceCamera.initialize(); //Add this

  runApp(const MyApp());
}
```

* Create a new `FaceCameraController` controller, setting the onCapture callback.
```dart
  late FaceCameraController controller;

  @override
  void initState() {
    controller = FaceCameraController(
      autoCapture: true,
      defaultCameraLens: CameraLens.front,
      onCapture: (File? image) {
        
      },
    );
  super.initState();
}
```

* Then render the component in your application using the required options.
```dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SmartFaceCamera(
          controller: controller,
          message: 'Center your face in the square',
        )
    );
  }
```

### Customization
---  

Here is a list of properties available to customize your widget:

| Name                      | Type                  | Description                                                                   |
|---------------------------|-----------------------|-------------------------------------------------------------------------------|
| controller                | FaceCameraController  | The controller for the [SmartFaceCamera] widget                               |
| showControls              | bool                  | set false to hide all controls                                                |
| showCaptureControl        | bool                  | set false to hide capture control icon                                        |
| showFlashControl          | bool                  | set false to hide flash control control icon                                  |
| showCameraLensControl     | bool                  | set false to hide camera lens control icon                                    |
| message                   | String                | use this pass a message above the camera                                      |
| messageStyle              | TextStyle             | style applied to the message widget                                           |
| lensControlIcon           | Widget                | use this to render a custom widget for camera lens control                    |
| flashControlBuilder       | FlashControlBuilder   | use this to build custom widgets for flash control based on camera flash mode |
| messageBuilder            | MessageBuilder        | use this to build custom messages based on face position                      |
| indicatorShape            | IndicatorShape        | use this to change the shape of the face indicator (defaultShape, square, circle, triangle, triangleInverted, image, fixedFrame, none) |
| indicatorAssetImage       | String                | use this to pass an asset image when IndicatorShape is set to image           |
| indicatorBuilder          | IndicatorBuilder      | use this to build custom widgets for the face indicator                       |
| captureControlBuilder     | CaptureControlBuilder | use this to build custom widgets for capture control                          |
| autoDisableCaptureControl | bool                  | set true to disable capture control widget when no face is detected           |

#### Fixed Frame Mode

The `IndicatorShape.fixedFrame` option displays a centered, fixed-size frame (70% of screen) instead of following the detected face. This provides a better user experience for face capture with real-time positioning guidance:

**Frame Colors:**
* **White/Gray Frame**: No face detected
* **Red Frame**: Face detected but requirements not met
* **Green Frame**: Face properly positioned, countdown starts

**Detection Constraints:**

For the frame to turn green and trigger auto-capture, the following conditions must ALL be met:

1. **Face Distance**
   - Eye distance must be between 0.14 - 0.28 (normalized Euclidean distance)
   - Too close (> 0.28) → "Move back"
   - Too far (< 0.14) → "Move closer"

2. **Landmark Positioning**
   - All 6 facial landmarks (both eyes, nose, 3 mouth points) must be inside the frame bounds (15% - 85% of screen)
   - Provides guidance: "Move left", "Move right", "Move up", "Move down"

3. **Face Centering**
   - Nose must be near the center of the frame (40% - 60% range)
   - Ensures face is not just inside, but properly centered

4. **Head Orientation**
   - Head rotation Y (left/right): ≤ 12 degrees
   - Head rotation Z (tilt): ≤ 12 degrees
   - User must face forward with head straight

**Basic Usage:**

```dart
FaceCameraController(
  autoCapture: true,
  captureDelay: 3,
  defaultCameraLens: CameraLens.front,
  showDebugLandmarks: false,
  onCapture: (File? image) {
    // Handle captured image
  },
)

SmartFaceCamera(
  controller: controller,
  indicatorShape: IndicatorShape.fixedFrame,
  messageBuilder: (context, face) {
    if (controller.value.countdown != null) {
      return _buildMessage('Hold still...');
    }

    final guidance = controller.getFacePositionGuidance();
    return _buildMessage(guidance ?? 'Ready');
  },
)

Widget _buildMessage(String message) => Padding(
  padding: EdgeInsets.symmetric(horizontal: 55, vertical: 15),
  child: Text(
    message,
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
  ),
);
```

**Customizing Guidance Messages:**

You can fully customize the positioning guidance messages:

```dart
messageBuilder: (context, face) {
  // Show countdown message
  if (controller.value.countdown != null) {
    return _buildMessage('Hold still... ${controller.value.countdown}');
  }

  // Get default guidance
  final guidance = controller.getFacePositionGuidance();

  // Customize messages
  String message;
  switch (guidance) {
    case 'Move closer':
      message = 'Come closer to the camera';
      break;
    case 'Move back':
      message = 'Move away from the camera';
      break;
    case 'Move left':
      message = 'Move to your left';
      break;
    case 'Move right':
      message = 'Move to your right';
      break;
    case 'Move up':
      message = 'Lift your phone higher';
      break;
    case 'Move down':
      message = 'Lower your phone';
      break;
    case 'Center your face':
      message = 'Almost there, center your face';
      break;
    case 'Place your face in the frame':
      message = 'Position your face in the frame';
      break;
    default:
      message = 'Perfect! Capturing...';
  }

  return _buildMessage(message);
}
```

**Multi-language Support:**

```dart
messageBuilder: (context, face) {
  if (controller.value.countdown != null) {
    return _buildMessage(AppLocalizations.of(context).holdStill);
  }

  final guidance = controller.getFacePositionGuidance();
  final translations = {
    'Move closer': AppLocalizations.of(context).moveCloser,
    'Move back': AppLocalizations.of(context).moveBack,
    'Move left': AppLocalizations.of(context).moveLeft,
    'Move right': AppLocalizations.of(context).moveRight,
    // ... more translations
  };

  return _buildMessage(
    translations[guidance] ?? AppLocalizations.of(context).ready
  );
}
```

**Debug Mode:**

Enable `showDebugLandmarks: true` in the controller to visualize facial landmarks with colored markers:
- Blue: Eyes
- Green: Nose
- Red: Mouth
- Yellow: Cheeks
- Purple: Ears
- Cyan: Face bounding box

This mode is ideal for KYC, document verification, and any application requiring consistent, high-quality face capture.

#### Capture Countdown

When `autoCapture` is enabled, you can add a countdown delay before the photo is taken. This gives users time to prepare and ensures they're ready:

```dart
FaceCameraController(
  autoCapture: true,
  captureDelay: 3, // 3-second countdown (default)
  onCapture: (File? image) {
    // Handle captured image
  },
)
```

The countdown is displayed as a large centered number (3, 2, 1) and only starts when the face is properly positioned. If the face moves out of position during countdown, the timer resets. Set `captureDelay: 0` for immediate capture without countdown.

\
\
Here is a list of properties available to customize your widget from the controller:

| Name                  | Type                    | Description                                                             |
|-----------------------|-------------------------|-------------------------------------------------------------------------|
| onCapture             | Function(File?)         | callback invoked when camera captures image                             |
| onFaceDetected        | Function(DetectedFace?) | callback invoked when camera detects face                               |
| imageResolution       | ImageResolution         | use this to set image resolution                                        |
| defaultCameraLens     | CameraLens              | use this to set initial camera lens direction                           |
| defaultFlashMode      | CameraFlashMode         | use this to set initial flash mode                                      |
| enableAudio           | bool                    | set false to disable capture sound                                      |
| autoCapture           | bool                    | set true to capture image on face detected                              |
| captureDelay          | int                     | countdown delay in seconds before auto-capture (default: 3, set 0 for immediate) |
| showDebugLandmarks    | bool                    | set true to show colored markers for facial landmarks (eyes, nose, mouth, etc.) |
| ignoreFacePositioning | bool                    | set true to trigger onCapture even when the face is not well positioned |
| orientation           | CameraOrientation       | use this to lock camera orientation                                     |
| performanceMode       | FaceDetectorMode        | use this to set your preferred performance mode                         |


### Contributions
---  

Contributions of any kind are more than welcome! Feel free to fork and improve `face_camera` in any way you want, make a pull request, or open an issue.

### Support the Library
---  

You can support the library by donating, liking it on Pub, starring it on GitHub, and reporting any bugs you encounter.

[![💖 Show Love on Selar](https://img.shields.io/badge/-💖_Show_Love_on_Selar-orange?logo=heart&logoColor=white)](https://selar.com/showlove/conezi)
