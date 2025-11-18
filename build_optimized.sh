#!/bin/bash

# Build optimized APK dengan ukuran minimal
# Usage: ./build_optimized.sh [release|debug]

BUILD_TYPE=${1:-release}

echo "🚀 Building OPTIMIZED $BUILD_TYPE APK..."
echo "📱 App: nhasix"
echo "📦 Version: $(grep 'version:' pubspec.yaml | sed 's/version: //')"
echo "📅 Date: $(date +%Y%m%d)"
echo ""

# Clean project
echo "🧹 Cleaning project..."
flutter clean > /dev/null 2>&1

echo "📊 OPTIMIZATION STRATEGIES:"
echo "✅ Split APK per ABI (arm64, arm)"
echo "✅ Enable Android R8 obfuscation (default)"
echo "✅ Compress native libraries"
echo "✅ Remove debug symbols"
echo ""

# Build split APKs for different architectures
echo "🔨 Building optimized APKs per architecture..."

# ARM64 (most common for modern devices)
echo "📱 Building ARM64 APK..."
if [ "$BUILD_TYPE" = "release" ]; then
    flutter build apk --release --target-platform android-arm64 --split-debug-info=build/debug-info/ --split-per-abi
else
    flutter build apk --debug --target-platform android-arm64 --split-per-abi
fi

# ARM (older devices)
echo "📱 Building ARM APK..."
if [ "$BUILD_TYPE" = "release" ]; then
    flutter build apk --release --target-platform android-arm --split-debug-info=build/debug-info/ --split-per-abi
else
    flutter build apk --debug --target-platform android-arm --split-per-abi
fi

# Universal APK (all architectures) - DISABLED for CI to avoid large file
# echo "📱 Building Universal APK..."
# if [ "$BUILD_TYPE" = "release" ]; then
#     flutter build apk --release --obfuscate --split-debug-info=build/debug-info/
# else
#     flutter build apk --debug
# fi

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

# Copy ARM64 APK
if [ -f "build/app/outputs/flutter-apk/app-arm64-v8a-${BUILD_TYPE}.apk" ]; then
    size=$(du -h "build/app/outputs/flutter-apk/app-arm64-v8a-${BUILD_TYPE}.apk" | cut -f1)
    version=$(grep 'version:' pubspec.yaml | sed 's/version: //' | cut -d'+' -f1)
    date=$(date +%Y%m%d)
    optimized_name="nhasix_${version}_${date}_${BUILD_TYPE}_arm64.apk"

    cp "build/app/outputs/flutter-apk/app-arm64-v8a-${BUILD_TYPE}.apk" "$OUTPUT_DIR/$optimized_name"
    echo "  📱 ARM64 APK: $optimized_name - $size"
fi

# Copy ARM APK
if [ -f "build/app/outputs/flutter-apk/app-armeabi-v7a-${BUILD_TYPE}.apk" ]; then
    size=$(du -h "build/app/outputs/flutter-apk/app-armeabi-v7a-${BUILD_TYPE}.apk" | cut -f1)
    version=$(grep 'version:' pubspec.yaml | sed 's/version: //' | cut -d'+' -f1)
    date=$(date +%Y%m%d)
    optimized_name="nhasix_${version}_${date}_${BUILD_TYPE}_arm.apk"

    cp "build/app/outputs/flutter-apk/app-armeabi-v7a-${BUILD_TYPE}.apk" "$OUTPUT_DIR/$optimized_name"
    echo "  📱 ARM APK: $optimized_name - $size"
fi

# Copy Universal APK - DISABLED
# if [ -f "build/app/outputs/flutter-apk/app-${BUILD_TYPE}.apk" ]; then
#     size=$(du -h "build/app/outputs/flutter-apk/app-${BUILD_TYPE}.apk" | cut -f1)
#     version=$(grep 'version:' pubspec.yaml | sed 's/version: //' | cut -d'+' -f1)
#     date=$(date +%Y%m%d)
#     optimized_name="nhasix_${version}_${date}_${BUILD_TYPE}_universal_optimized.apk"
# 
#     cp "build/app/outputs/flutter-apk/app-${BUILD_TYPE}.apk" "$OUTPUT_DIR/$optimized_name"
#     echo "  📱 Universal APK: $optimized_name - $size"
# fi

echo ""
echo "📏 SIZE COMPARISON:"
echo "📦 Original (universal): ~29MB"
echo "✨ ARM64: $(du -h $OUTPUT_DIR/nhasix_*_${BUILD_TYPE}_arm64.apk 2>/dev/null | cut -f1 || echo 'N/A')"
echo "✨ ARM: $(du -h $OUTPUT_DIR/nhasix_*_${BUILD_TYPE}_arm.apk 2>/dev/null | cut -f1 || echo 'N/A')"
echo "✨ Universal: DISABLED (too large for CI upload)"

echo ""
echo "📂 All APKs saved to: $OUTPUT_DIR/"
echo ""

echo ""
echo "🎯 RECOMMENDATIONS:"
echo "📱 Use ARM64 APK for modern devices (95% of users)"
echo "📱 Use ARM APK for older devices (compatibility)"
echo "🚀 Upload to Google Play as App Bundle for automatic optimization"
echo "⚠️ Universal APK disabled in CI to avoid upload limits"
echo ""
echo "🎉 Optimization complete! All APKs ready in $OUTPUT_DIR/"
