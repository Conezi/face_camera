# face_camera

### A Flutter camera plugin that detects face in real-time.

## Installation
First, add `face_camera` as a dependency in your pubspec.yaml file.

```yaml  
face_camera: ^0.0.1
```

## iOS
* Minimum iOS Deployment Target: 10.0
* Xcode 13 or newer
* Swift 5
* `face_camera` only supports 64-bit architectures (x86_64 and arm64). Check this <a href="https://developer.apple.com/support/required-device-capabilities/">list</a> to see if your device has the required device capabilities.

Since `face_camera` does not support 32-bit architectures (i386 and armv7), you need to exclude amrv7 architectures in Xcode in order to run `flutter build` ios or `flutter build ipa`.




Add two rows to the `ios/Runner/Info.plist:`

* one with the key `Privacy - Camera Usage Description` and a usage description.
* and one with the `key Privacy - Microphone Usage Description` and a usage description.

If editing `Info.plist` as text, add:

```xml  
<key>NSCameraUsageDescription</key>
<string>your usage description here</string>
<key>NSMicrophoneUsageDescription</key>
<string>your usage description here</string>
  
```


## Android
* Change the minimum Android sdk version to 21 (or higher) in your android/app/build.gradle file.

```groovy
minSdkVersion 21
```


### Support the Library

You can support the library by liking it on pub, staring in on Github and reporting any bugs you encounter.