#!/bin/bash

# TrailRun iOS Build Script
# Comprehensive build script for iOS development and deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BUILD_TYPE=${1:-debug}
CLEAN=${2:-false}

echo -e "${BLUE}🏃‍♂️ TrailRun iOS Build Script${NC}"
echo -e "${BLUE}Build Type: ${BUILD_TYPE}${NC}"
echo ""

# Validate build type
case $BUILD_TYPE in
    debug|release|profile)
        ;;
    *)
        echo -e "${RED}❌ Invalid build type. Use: debug, release, or profile${NC}"
        exit 1
        ;;
esac

# Clean if requested
if [ "$CLEAN" = "true" ] || [ "$CLEAN" = "clean" ]; then
    echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
    flutter clean
    cd ios
    rm -rf Pods/
    rm -rf .symlinks/
    rm -f Podfile.lock
    rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
    cd ..
fi

echo -e "${BLUE}📦 Step 1: Installing Flutter dependencies...${NC}"
flutter pub get

echo -e "${BLUE}🔨 Step 2: Running code generation...${NC}"
flutter packages pub run build_runner build --delete-conflicting-outputs

echo -e "${BLUE}📱 Step 3: Setting up iOS dependencies...${NC}"
cd ios
pod install --repo-update
cd ..

echo -e "${BLUE}🏗️ Step 4: Building iOS app (${BUILD_TYPE})...${NC}"
case $BUILD_TYPE in
    debug)
        flutter build ios --debug --no-codesign
        ;;
    release)
        flutter build ios --release
        ;;
    profile)
        flutter build ios --profile
        ;;
esac

echo -e "${GREEN}✅ iOS build completed successfully!${NC}"
echo ""

# Build information
echo -e "${YELLOW}📋 Build Information:${NC}"
echo "• Build Type: $BUILD_TYPE"
echo "• Flutter Version: $(flutter --version | head -n 1)"
echo "• iOS Deployment Target: 13.0"
echo "• Bundle ID: com.trailrun.app"
echo ""

# Next steps based on build type
case $BUILD_TYPE in
    debug)
        echo -e "${YELLOW}🚀 Next Steps (Debug):${NC}"
        echo "1. Open ios/Runner.xcworkspace in Xcode"
        echo "2. Select your device/simulator"
        echo "3. Press ⌘+R to run the app"
        echo "4. Enable location services in simulator settings"
        ;;
    release)
        echo -e "${YELLOW}🚀 Next Steps (Release):${NC}"
        echo "1. Open ios/Runner.xcworkspace in Xcode"
        echo "2. Select 'Any iOS Device' as target"
        echo "3. Product → Archive to create distribution build"
        echo "4. Upload to App Store Connect or export for TestFlight"
        ;;
    profile)
        echo -e "${YELLOW}🚀 Next Steps (Profile):${NC}"
        echo "1. Open ios/Runner.xcworkspace in Xcode"
        echo "2. Select your physical device (required for profiling)"
        echo "3. Product → Profile to launch Instruments"
        echo "4. Choose appropriate profiling template (Time Profiler, Allocations, etc.)"
        ;;
esac

echo ""
echo -e "${BLUE}📚 Additional Commands:${NC}"
echo "• Clean build: ./build_ios.sh $BUILD_TYPE clean"
echo "• Run tests: flutter test"
echo "• Run integration tests: flutter test integration_test/"
echo "• Analyze code: flutter analyze"
echo ""

# Performance tips
echo -e "${YELLOW}💡 Performance Tips:${NC}"
echo "• Use Profile builds for performance testing"
echo "• Test on physical devices for accurate GPS/camera functionality"
echo "• Monitor battery usage during long tracking sessions"
echo "• Use Xcode Instruments for detailed performance analysis"