#import "FaceCameraPlugin.h"
#if __has_include(<face_camera/face_camera-Swift.h>)
#import <face_camera/face_camera-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "face_camera-Swift.h"
#endif

@implementation FaceCameraPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFaceCameraPlugin registerWithRegistrar:registrar];
}
@end
