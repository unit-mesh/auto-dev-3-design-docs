#!/usr/bin/env zsh
set -euo pipefail

# Run AutoDev iOS app on a physical device
# Usage:
#   docs/test-scripts/run-on-ios-device.sh                # Build frameworks, install pods, open Xcode workspace
#   docs/test-scripts/run-on-ios-device.sh <DEVICE_UDID>  # Build and xcodebuild for the given device UDID

SCRIPT_DIR=${0:A:h}
ROOT_DIR=${SCRIPT_DIR}/../..
ROOT_DIR=$(cd "$ROOT_DIR" && pwd)

cd "$ROOT_DIR"
echo "📦 Building Kotlin frameworks for iOS device (iosArm64)..."
./gradlew :mpp-core:linkDebugFrameworkIosArm64 :mpp-ui:linkDebugFrameworkIosArm64 --no-daemon

echo "📦 Installing CocoaPods and preparing Xcode workspace..."
cd mpp-ios
pod install

if [[ $# -gt 0 ]]; then
  UDID="$1"
  echo "🚀 Building app for device $UDID via xcodebuild..."
  xcodebuild \
    -workspace AutoDevApp.xcworkspace \
    -scheme AutoDevApp \
    -configuration Debug \
    -destination "id=${UDID}" \
    build
  echo "✅ Build completed for device $UDID. If not auto-installed, open Xcode and run."
else
  echo "🚀 Opening Xcode workspace. Select your device and press Run (⌘R)."
  open AutoDevApp.xcworkspace
fi
