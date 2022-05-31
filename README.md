# face_camera

A Flutter camera plugin that detects face in real-time.

Installation
First, add face_camera as a dependency in your pubspec.yaml file.

iOS
* The face_camera plugin compiles for any version of iOS, but its functionality requires iOS 10 or higher. If compiling for iOS 9, make sure to programmatically check the version of iOS running on the device before using any camera plugin features. The device_info_plus plugin, for example, can be used to check the iOS version.

Add two rows to the ios/Runner/Info.plist:

one with the key Privacy - Camera Usage Description and a usage description.
and one with the key Privacy - Microphone Usage Description and a usage description.
If editing Info.plist as text, add:

<key>NSCameraUsageDescription</key>
<string>your usage description here</string>
<key>NSMicrophoneUsageDescription</key>
<string>your usage description here</string>


Android
Change the minimum Android sdk version to 21 (or higher) in your android/app/build.gradle file.

minSdkVersion 21


It's important to note that the MediaRecorder class is not working properly on emulators, as stated in the documentation: https://developer.android.com/reference/android/media/MediaRecorder. Specifically, when recording a video with sound enabled and trying to play it back, the duration won't be correct and you will only see the first frame.

