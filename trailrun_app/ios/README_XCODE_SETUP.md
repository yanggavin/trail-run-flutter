# TrailRun iOS - Xcode Setup Guide

This guide will help you set up the TrailRun iOS project for development in Xcode.

## 🚀 Quick Setup

### Automated Setup
Run the setup script from the `ios` directory:
```bash
cd ios
./setup_xcode.sh
```

### Manual Setup
If you prefer to set up manually, follow these steps:

## 📋 Prerequisites

- **Xcode 15.0+** with iOS 13.0+ SDK
- **Flutter SDK** (latest stable version)
- **CocoaPods** (`sudo gem install cocoapods`)
- **Apple Developer Account** (for device testing and App Store deployment)

## 🔧 Project Configuration

### 1. Bundle Identifier
- **Current**: `com.trailrun.app`
- **Update in**: 
  - `ios/Flutter/Debug.xcconfig`
  - `ios/Flutter/Release.xcconfig` 
  - `ios/Flutter/Profile.xcconfig`

### 2. Development Team
Replace `YOUR_TEAM_ID` in the `.xcconfig` files with your Apple Developer Team ID:
```
DEVELOPMENT_TEAM = ABCD123456
```

### 3. App Display Name
- **Current**: "TrailRun"
- **Update in**: `ios/Runner/Info.plist` → `CFBundleDisplayName`

## 🏗️ Build Configuration

### Debug Configuration
- **Optimization**: None (`-Onone`)
- **Active Architecture Only**: YES
- **Debug Symbols**: Full

### Release Configuration  
- **Optimization**: Optimize for Speed (`-O`)
- **Compilation Mode**: Whole Module
- **Debug Symbols**: dSYM file
- **Validation**: Enabled

### Profile Configuration
- **Optimization**: Optimize for Speed (`-O`)
- **Debug Symbols**: dSYM file (for performance profiling)
- **Validation**: Enabled

## 🔐 Permissions & Capabilities

### Required Permissions (Info.plist)
- **Location When In Use**: GPS tracking during active use
- **Location Always**: Background GPS tracking
- **Camera**: Photo capture during runs
- **Photo Library**: Saving captured photos

### Background Modes
- **Location updates**: Continue tracking in background
- **Background fetch**: Sync data when app launches
- **Background processing**: Handle data processing tasks

### App Transport Security
- **Arbitrary Loads**: Disabled (security)
- **Local Networking**: Enabled (for development)

## 📱 Device Capabilities

### Required
- **Location Services**: Core functionality
- **GPS**: Accurate positioning
- **Camera**: Photo capture feature

### Recommended
- **Accelerometer**: Motion detection
- **Gyroscope**: Enhanced motion tracking
- **Magnetometer**: Compass functionality

## 🔧 Xcode Project Structure

```
Runner.xcworkspace/          # ← Open this in Xcode
├── Runner.xcodeproj/
├── Pods/                    # CocoaPods dependencies
├── Flutter/                 # Flutter framework
└── Runner/                  # iOS app source
    ├── AppDelegate.swift    # App lifecycle
    ├── BackgroundLocationManager.swift  # Background tracking
    ├── Info.plist          # App configuration
    ├── Runner.entitlements # App capabilities
    └── Assets.xcassets     # App icons & images
```

## 🚀 Building & Running

### In Xcode
1. Open `Runner.xcworkspace` (NOT `.xcodeproj`)
2. Select target device/simulator
3. Choose build configuration (Debug/Release/Profile)
4. Press ⌘+R to build and run

### Command Line
```bash
# Debug build
flutter build ios --debug

# Release build  
flutter build ios --release

# Profile build (for performance testing)
flutter build ios --profile
```

## 🧪 Testing

### Unit Tests
```bash
# Run Flutter tests
flutter test

# Run iOS unit tests in Xcode
⌘+U in Xcode
```

### Integration Tests
```bash
# Run integration tests on device
flutter test integration_test/app_test.dart
```

### Performance Testing
- Use Xcode Instruments for performance profiling
- Profile build configuration recommended
- Test on physical devices for accurate results

## 🔍 Debugging

### Flutter Inspector
- Available in VS Code and Android Studio
- Real-time widget tree inspection
- Performance monitoring

### Xcode Debugger
- Breakpoints in Swift/Objective-C code
- Memory graph debugger
- Network debugging

### Console Logging
```dart
// Flutter logging
print('Debug message');
debugPrint('Debug message');

// iOS native logging
os_log("Message", log: OSLog.default, type: .info)
```

## 📦 Dependencies Management

### Flutter Dependencies
```bash
flutter pub get
flutter pub upgrade
```

### iOS Dependencies (CocoaPods)
```bash
cd ios
pod install
pod update
```

### Common Issues
- **Pod install fails**: Update CocoaPods (`sudo gem update cocoapods`)
- **Build fails**: Clean build folder (⌘+Shift+K) and rebuild
- **Simulator issues**: Reset simulator content and settings

## 🚀 Deployment

### TestFlight (Beta Testing)
1. Archive build in Xcode (⌘+Shift+B)
2. Upload to App Store Connect
3. Add beta testers
4. Distribute build

### App Store Release
1. Create App Store listing in App Store Connect
2. Upload release build
3. Submit for review
4. Release when approved

## 🔧 Advanced Configuration

### Custom URL Schemes
Add to `Info.plist` for deep linking:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.trailrun.app</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>trailrun</string>
        </array>
    </dict>
</array>
```

### Push Notifications
1. Enable Push Notifications capability in Xcode
2. Configure APNs certificates in Apple Developer Portal
3. Add Firebase Cloud Messaging configuration

### App Extensions
- **Today Widget**: Quick stats on lock screen
- **Watch App**: Apple Watch companion
- **Siri Shortcuts**: Voice commands for starting runs

## 🐛 Troubleshooting

### Common Build Errors

**Error**: "No such module 'Flutter'"
**Solution**: Ensure you opened `.xcworkspace` not `.xcodeproj`

**Error**: "Undefined symbols for architecture arm64"
**Solution**: Clean build folder and run `pod install`

**Error**: "Code signing error"
**Solution**: Update development team and provisioning profiles

### Performance Issues

**Issue**: App crashes on launch
**Solution**: Check console logs and crash reports in Xcode

**Issue**: High memory usage
**Solution**: Use Xcode Memory Graph Debugger to identify leaks

**Issue**: Poor GPS accuracy
**Solution**: Test on physical device with clear sky view

## 📚 Resources

- [Flutter iOS Deployment Guide](https://docs.flutter.dev/deployment/ios)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Xcode User Guide](https://developer.apple.com/documentation/xcode)
- [CocoaPods Guides](https://guides.cocoapods.org/)

## 🆘 Support

For TrailRun-specific issues:
1. Check the main README.md for general setup
2. Review task implementation summaries for feature details
3. Run integration tests to verify functionality
4. Check GitHub issues for known problems

---

**Happy coding! 🏃‍♂️📱**