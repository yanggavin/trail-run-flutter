#!/bin/bash

# TrailRun iOS Build Issue Fix Script
# This script fixes common "PhaseScriptExecution failed" errors

set -e

echo "🔧 Fixing iOS build issues..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Step 1: Cleaning build artifacts...${NC}"
# Clean Xcode derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Clean local build files
rm -rf build/
rm -rf .dart_tool/
rm -rf ios/build/
rm -rf ios/.symlinks/
rm -rf ios/Pods/
rm -f ios/Podfile.lock

echo -e "${BLUE}Step 2: Cleaning Flutter...${NC}"
cd ..
flutter clean
flutter pub get

echo -e "${BLUE}Step 3: Reinstalling CocoaPods...${NC}"
cd ios

# Update CocoaPods repo
pod repo update

# Install pods with verbose output to catch errors
pod install --verbose

echo -e "${BLUE}Step 4: Fixing common script issues...${NC}"

# Fix permissions on script files
find . -name "*.sh" -exec chmod +x {} \;

# Create missing directories that might cause script failures
mkdir -p Flutter/ephemeral
mkdir -p Runner.xcodeproj/xcshareddata/xcschemes

echo -e "${BLUE}Step 5: Generating Flutter iOS configuration...${NC}"
cd ..
flutter build ios --config-only

echo -e "${GREEN}✅ Build issue fixes applied!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Open ios/Runner.xcworkspace in Xcode"
echo "2. Clean build folder in Xcode (⌘+Shift+K)"
echo "3. Build the project (⌘+B)"
echo ""
echo -e "${YELLOW}If you still get script errors:${NC}"
echo "• Check Xcode build logs for specific error details"
echo "• Ensure your Apple Developer account is properly configured"
echo "• Make sure you have the latest Xcode version"
echo "• Try building on a physical device instead of simulator"