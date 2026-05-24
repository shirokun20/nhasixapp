#!/bin/bash

set -euo pipefail

# Build optimized APK dengan ukuran minimal
# Usage: ./build_optimized.sh [release|debug]

BUILD_TYPE=${1:-release}

APP_ID="id.nhasix.app"
APP_NAME="Kuron"

if [ "$BUILD_TYPE" = "debug" ]; then
    APP_ID="${APP_ID}.debug"
    APP_NAME="Kuron Dev"
fi

echo "🚀 Building OPTIMIZED $BUILD_TYPE APK..."
echo "📱 App: $APP_NAME ($APP_ID)"
echo "📦 Version: $(grep 'version:' pubspec.yaml | sed 's/version: //')"
echo "📅 Date: $(date +%Y%m%d)"
echo ""

# Clean project
echo "🧹 Cleaning project..."
flutter clean > /dev/null 2>&1

echo "📊 OPTIMIZATION STRATEGIES:"
echo "✅ Split APK per ABI (arm64, arm, x86_64) - Flutter --split-per-abi"
echo "✅ Enable Android R8 obfuscation + minify"
echo "✅ Compress native libraries"
echo "✅ Remove debug symbols"
echo "✅ Shrink resources"
echo ""

# Build with Flutter's --split-per-abi flag (generates all ABIs in one command)
echo "🔨 Building optimized APKs (automatic split per architecture)..."

# Auto-export KEYSTORE_BASE64 for release builds if local file exists.
if [ "$BUILD_TYPE" = "release" ] && [ -z "${KEYSTORE_BASE64:-}" ] && [ -f "android/keystore_base64.txt" ]; then
    KEYSTORE_BASE64=$(tr -d '\n' < android/keystore_base64.txt)
    export KEYSTORE_BASE64
    echo "🔐 Loaded KEYSTORE_BASE64 from android/keystore_base64.txt"
fi

if [ "$BUILD_TYPE" = "release" ]; then
    flutter build apk --release --split-per-abi --split-debug-info=build/debug-info/
else
    flutter build apk --debug --split-per-abi
fi

echo ""
echo "✅ Optimized builds completed!"
echo ""

# Create output directory
OUTPUT_DIR="apk-output"
mkdir -p "$OUTPUT_DIR"

# Show results and copy files
echo "📁 OPTIMIZED APK FILES:"
echo "📂 Output directory: $OUTPUT_DIR/"
echo ""

# Find and copy all split APKs
# Note: Renamed via android/app/build.gradle to kuron_*.apk
# Location: build/app/outputs/apk/release/ or build/app/outputs/apk/debug/
APK_SEARCH_PATH="build/app/outputs/apk/$BUILD_TYPE/kuron_*.apk"

FOUND_COUNT=0
for apk in $APK_SEARCH_PATH; do
    if [ -f "$apk" ]; then
        filename=$(basename "$apk")
        size=$(du -h "$apk" | cut -f1)
        cp "$apk" "$OUTPUT_DIR/"
        echo "  📱 $filename - $size"
        FOUND_COUNT=$((FOUND_COUNT + 1))
    fi
done

if [ $FOUND_COUNT -eq 0 ]; then
    echo "❌ Error: No APK files found matching $APK_SEARCH_PATH"
    echo "Check build output directory!"
    exit 1
fi

echo ""
echo "📏 SIZE SUMMARY:"
total_size=$(du -ch $OUTPUT_DIR/kuron_*.apk 2>/dev/null | grep total | cut -f1 || echo '0')
count=$(ls -1 $OUTPUT_DIR/kuron_*.apk 2>/dev/null | wc -l | tr -d ' ')
universal_apk_path="build/app/outputs/flutter-apk/app-${BUILD_TYPE}.apk"
echo "📦 Total APKs: $count"
echo "📊 Combined size: $total_size"
if [ -f "$universal_apk_path" ]; then
    universal_size=$(du -h "$universal_apk_path" | cut -f1)
    echo "💾 Universal APK reference: $universal_size ($(basename "$universal_apk_path"))"
else
    echo "💾 Universal APK reference: N/A (not generated with --split-per-abi)"
fi
echo ""
echo "📂 All APKs saved to: $OUTPUT_DIR/"
echo ""

echo ""
echo "🎯 RECOMMENDATIONS:"
echo "📱 Use ARM64 APK for modern devices (95% of users)"
echo "📱 Use ARM APK for older devices (compatibility)"
echo "📱 x86_64 APK also generated (for emulators/ChromeOS)"
echo "🚀 Upload to Google Play as App Bundle for automatic optimization"
echo "⚡ Single Flutter command generates all ABIs automatically"
echo ""
echo "🎉 Optimization complete! All APKs ready in $OUTPUT_DIR/"
