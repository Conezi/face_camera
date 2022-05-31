# face_camera

### A Flutter camera plugin that detects face in real-time.

## Installation
First, add `face_camera` as a dependency in your pubspec.yaml file.

```yaml  
face_camera: ^0.0.1
```

## iOS
* The `face_camera` plugin compiles for any version of iOS, but its functionality requires iOS 10 or higher. If compiling for iOS 9, make sure to programmatically check the version of iOS running on the device before using any camera plugin features. The device_info_plus plugin, for example, can be used to check the iOS version.

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
Change the minimum Android sdk version to 21 (or higher) in your android/app/build.gradle file.

```groovy
minSdkVersion 21
```


### Support the Library

You can support the library by liking it on pub, staring in on Github and reporting any bugs you encounter.