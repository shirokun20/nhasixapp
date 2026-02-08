#!/bin/bash


# Build optimized APK dengan ukuran minimal
# Usage: ./build_optimized.sh [release|debug]

BUILD_TYPE=${1:-release}

APP_ID="id.komiktap.mobile"
APP_NAME="Komik Tap mobile"

if [ "$BUILD_TYPE" = "debug" ]; then
    APP_ID="${APP_ID}.debug"
    APP_NAME="Komik Tap mobile Dev"
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
echo "✅ Universal APK (fat APK) - Single APK for all architectures"
echo "✅ Enable Android R8 obfuscation + minify"
echo "✅ Compress native libraries"
echo "✅ Remove debug symbols"
echo "✅ Shrink resources"
echo ""

# Build optimized universal APK
echo "🔨 Building optimized APK (universal)..."

if [ "$BUILD_TYPE" = "release" ]; then
    flutter build apk --release
else
    flutter build apk --debug
fi

echo ""
echo "✅ Optimized build completed!"
echo ""

# Create output directory
OUTPUT_DIR="apk-output"
mkdir -p "$OUTPUT_DIR"

# Show results and copy files
echo "📁 OPTIMIZED APK FILES:"
echo "📂 Output directory: $OUTPUT_DIR/"
echo ""

# Find and copy universal APK
# Note: Renamed via android/app/build.gradle to komiktap_*.apk
# Location: build/app/outputs/apk/release/ or build/app/outputs/apk/debug/
APK_SEARCH_PATH="build/app/outputs/apk/$BUILD_TYPE/komiktap_*.apk"

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
total_size=$(du -ch $OUTPUT_DIR/komiktap_*.apk 2>/dev/null | grep total | cut -f1 || echo '0')
echo "📦 Total APKs: $FOUND_COUNT"
echo "📊 Total size: $total_size"
echo ""
echo "📂 APK saved to: $OUTPUT_DIR/"
echo ""

echo ""
echo "🎯 RECOMMENDATIONS:"
echo "📱 Universal APK works on all devices (ARM64, ARM, x86_64, etc)"
echo "� Useful if split APKs cause issues with native libraries or loading"
echo "⚡ Single Flutter command generates all ABIs automatically"
echo ""
echo "🎉 Optimization complete! All APKs ready in $OUTPUT_DIR/"
