# iOS Build Error Troubleshooting Guide

## "Command PhaseScriptExecution failed with a nonzero exit code"

This error is common in iOS Flutter projects and can have several causes. Here's a comprehensive troubleshooting guide.

## 🔧 Quick Fix (Run This First)

```bash
cd ios
./fix_build_issues.sh
```

## 🔍 Common Causes & Solutions

### 1. CocoaPods Issues

**Symptoms:**
- Pod install fails
- Missing dependencies
- Version conflicts

**Solutions:**
```bash
# Clean and reinstall pods
cd ios
rm -rf Pods Podfile.lock .symlinks
pod repo update
pod install --repo-update

# If still failing, update CocoaPods
sudo gem update cocoapods
```

### 2. Xcode Derived Data Issues

**Symptoms:**
- Build succeeds sometimes, fails other times
- "No such module" errors
- Cached build artifacts

**Solutions:**
```bash
# Clean Xcode derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# In Xcode: Product → Clean Build Folder (⌘+Shift+K)
```

### 3. Flutter Configuration Issues

**Symptoms:**
- Flutter framework not found
- Generated.xcconfig missing
- Plugin registration errors

**Solutions:**
```bash
# Clean Flutter build
flutter clean
flutter pub get
flutter build ios --config-only
```

### 4. Code Signing Issues

**Symptoms:**
- "Code signing error"
- "No matching provisioning profile"
- Team ID not set

**Solutions:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target → Signing & Capabilities
3. Choose your Apple Developer Team
4. Update `YOUR_TEAM_ID` in `.xcconfig` files with your actual team ID

### 5. Architecture Conflicts (M1 Macs)

**Symptoms:**
- "building for iOS Simulator, but linking in object file built for iOS"
- arm64 architecture errors

**Solutions:**
Already fixed in our Podfile:
```ruby
config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
```

### 6. Script Permission Issues

**Symptoms:**
- "Permission denied" in build logs
- Script execution fails

**Solutions:**
```bash
# Fix script permissions
find ios -name "*.sh" -exec chmod +x {} \;
```

## 📋 Step-by-Step Troubleshooting

### Step 1: Basic Cleanup
```bash
# From project root
flutter clean
cd ios
rm -rf Pods Podfile.lock .symlinks build
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
```

### Step 2: Reinstall Dependencies
```bash
# Still in ios directory
pod install --repo-update
cd ..
flutter pub get
```

### Step 3: Regenerate iOS Configuration
```bash
flutter build ios --config-only
```

### Step 4: Open in Xcode
```bash
open ios/Runner.xcworkspace
```

### Step 5: Configure Signing
1. Select Runner target
2. Go to Signing & Capabilities
3. Select your development team
4. Ensure bundle identifier is unique

### Step 6: Clean Build in Xcode
- Product → Clean Build Folder (⌘+Shift+K)
- Product → Build (⌘+B)

## 🔍 Specific Error Messages

### "No such module 'Flutter'"
**Cause:** Opening .xcodeproj instead of .xcworkspace
**Solution:** Always open `Runner.xcworkspace`

### "library not found for -lPods-Runner"
**Cause:** CocoaPods not properly integrated
**Solution:** 
```bash
cd ios
pod deintegrate
pod install
```

### "Multiple commands produce"
**Cause:** Duplicate build phases or targets
**Solution:** Check Xcode build phases for duplicates

### "The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to..."
**Cause:** Deployment target mismatch
**Solution:** Already fixed in our configuration (iOS 13.0)

### "Command CodeSign failed with a nonzero exit code"
**Cause:** Code signing configuration issues
**Solution:** 
1. Check Apple Developer account status
2. Verify provisioning profiles
3. Update team ID in project settings

## 🛠️ Advanced Troubleshooting

### Check Build Logs
1. In Xcode, open Report Navigator (⌘+9)
2. Select the failed build
3. Look for specific error messages
4. Expand script phases to see detailed errors

### Verbose Pod Install
```bash
cd ios
pod install --verbose
```

### Check Flutter Doctor
```bash
flutter doctor -v
```

### Verify Xcode Command Line Tools
```bash
xcode-select --print-path
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

## 🔄 Reset Everything (Nuclear Option)

If all else fails, complete reset:

```bash
# 1. Clean everything
flutter clean
cd ios
rm -rf Pods Podfile.lock .symlinks build
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 2. Reset Flutter
cd ..
flutter pub cache repair
flutter pub get

# 3. Reinstall pods
cd ios
pod repo update
pod install

# 4. Regenerate iOS config
cd ..
flutter build ios --config-only

# 5. Open fresh in Xcode
open ios/Runner.xcworkspace
```

## 📱 Device vs Simulator Issues

### Simulator-Specific Issues
- Limited location services
- No camera access
- Different architecture (x86_64 vs arm64)

### Device-Specific Issues
- Code signing required
- Provisioning profiles needed
- USB connection issues

**Recommendation:** Test on both simulator and physical device

## 🆘 Getting Help

### Check These First
1. Xcode build logs (detailed error messages)
2. Flutter doctor output
3. CocoaPods version (`pod --version`)
4. Xcode version compatibility

### Common Information Needed
- Xcode version
- Flutter version (`flutter --version`)
- macOS version
- Specific error message from build logs
- Whether it's simulator or device build

### Useful Commands for Debugging
```bash
# Check Flutter environment
flutter doctor -v

# Check CocoaPods environment
pod env

# Check Xcode version
xcodebuild -version

# List available simulators
xcrun simctl list devices

# Check code signing identity
security find-identity -v -p codesigning
```

## ✅ Prevention Tips

1. **Always open .xcworkspace, never .xcodeproj**
2. **Keep Xcode and Flutter updated**
3. **Use consistent iOS deployment target (13.0)**
4. **Regularly clean build artifacts**
5. **Keep CocoaPods updated**
6. **Use version control for Podfile.lock**
7. **Test on both simulator and device**

---

**Remember:** Most iOS build issues are environment-related and can be resolved with proper cleanup and reconfiguration. The automated fix script should resolve 90% of common issues.