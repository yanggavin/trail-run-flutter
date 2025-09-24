#!/bin/bash

# TrailRun iOS Xcode Setup Script
# This script prepares the iOS project for development in Xcode

set -e

echo "🏃‍♂️ Setting up TrailRun iOS project for Xcode..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "Podfile" ]; then
    echo -e "${RED}❌ Error: Podfile not found. Please run this script from the ios directory.${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Step 1: Cleaning previous builds...${NC}"
rm -rf Pods/
rm -rf .symlinks/
rm -f Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*

echo -e "${BLUE}📋 Step 2: Installing CocoaPods dependencies...${NC}"
if ! command -v pod &> /dev/null; then
    echo -e "${RED}❌ CocoaPods not found. Installing...${NC}"
    sudo gem install cocoapods
fi

pod install --repo-update

echo -e "${BLUE}📋 Step 3: Setting up Flutter dependencies...${NC}"
cd ..
flutter clean
flutter pub get
flutter packages pub run build_runner build --delete-conflicting-outputs

echo -e "${BLUE}📋 Step 4: Generating iOS platform files...${NC}"
cd ios
flutter build ios --config-only

echo -e "${BLUE}📋 Step 5: Configuring Xcode project settings...${NC}"

# Create schemes directory if it doesn't exist
mkdir -p Runner.xcodeproj/xcshareddata/xcschemes

# Set up the Runner scheme
cat > Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.3">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "97C146ED1CF9000F007C117D"
               BuildableName = "Runner.app"
               BlueprintName = "Runner"
               ReferencedContainer = "container:Runner.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "331C8081294A63A400263BE5"
               BuildableName = "RunnerTests.xctest"
               BlueprintName = "RunnerTests"
               ReferencedContainer = "container:Runner.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "97C146ED1CF9000F007C117D"
            BuildableName = "Runner.app"
            BlueprintName = "Runner"
            ReferencedContainer = "container:Runner.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
      <LocationScenarioReference
         identifier = "com.apple.dt.IDEFoundation.CurrentLocationScenarioIdentifier"
         referenceType = "1">
      </LocationScenarioReference>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Profile"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "97C146ED1CF9000F007C117D"
            BuildableName = "Runner.app"
            BlueprintName = "Runner"
            ReferencedContainer = "container:Runner.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
EOF

echo -e "${GREEN}✅ Xcode project setup complete!${NC}"
echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "1. Open Runner.xcworkspace (NOT Runner.xcodeproj) in Xcode"
echo "2. Select your development team in the Signing & Capabilities tab"
echo "3. Update the bundle identifier if needed (currently: com.trailrun.app)"
echo "4. Replace GoogleService-Info.plist with your Firebase configuration"
echo "5. Configure your Apple Developer account for location and background capabilities"
echo ""
echo -e "${BLUE}🚀 You can now build and run the TrailRun app in Xcode!${NC}"
echo ""
echo -e "${YELLOW}⚠️  Important notes:${NC}"
echo "• Always open Runner.xcworkspace, not Runner.xcodeproj"
echo "• Make sure to enable location services in iOS Simulator"
echo "• For background location testing, use a physical device"
echo "• Update YOUR_TEAM_ID in the .xcconfig files with your actual team ID"