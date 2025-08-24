#!/bin/bash

# Build APK dengan custom naming: nhasix_[version]_[date]_[buildType].apk
# Usage: ./build_apk.sh [release|debug]

BUILD_TYPE=${1:-debug}

echo "🚀 Building $BUILD_TYPE APK with custom naming..."
echo "📱 App: nhasix"
echo "📦 Version: $(grep 'version:' pubspec.yaml | sed 's/version: //')"
echo "📅 Date: $(date +%Y%m%d)"
echo ""

# Clean project
echo "🧹 Cleaning project..."
flutter clean

# Build APK
echo "🔨 Building APK..."
if [ "$BUILD_TYPE" = "release" ]; then
    flutter build apk --release
else
    flutter build apk --debug
fi

# Show output location
echo ""
echo "✅ Build completed!"
echo "📁 Custom named APK location:"
find build -name "*${BUILD_TYPE}*.apk" -path "*/apk/*" -type f | head -1

# Optional: Copy to project root for easy access
CUSTOM_APK=$(find build -name "*${BUILD_TYPE}*.apk" -path "*/apk/*" -type f | head -1)
if [ -n "$CUSTOM_APK" ]; then
    FILENAME=$(basename "$CUSTOM_APK")
    cp "$CUSTOM_APK" "./$FILENAME"
    echo "📋 Copied to project root: ./$FILENAME"
fi

echo ""
echo "🎉 Done! Custom APK naming format: nhasix_[version]_[date]_[buildType].apk"
