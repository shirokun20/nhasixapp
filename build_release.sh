#!/bin/bash

# Quick release build dengan custom naming
# Usage: ./build_release.sh

echo "🚀 Building RELEASE APK dengan custom naming..."
echo "📱 App: Kuron"
echo "📦 Version: $(grep 'version:' pubspec.yaml | sed 's/version: //')"
echo "📅 Date: $(date +%Y%m%d)"
echo ""

# Clean dan build release
echo "🧹 Cleaning..."
flutter clean > /dev/null 2>&1

echo "🔨 Building release APK..."
flutter build apk --release

# Show hasil
echo ""
echo "✅ Release build completed!"

CUSTOM_APK=$(find build -name "*release*.apk" -path "*/apk/*" -type f | head -1)
if [ -n "$CUSTOM_APK" ]; then
    echo "📁 Custom APK: $CUSTOM_APK"
    
    # Copy ke root untuk mudah akses
    FILENAME=$(basename "$CUSTOM_APK")
    cp "$CUSTOM_APK" "./$FILENAME"
    echo "📋 Copied to: ./$FILENAME"
    
    # Show file size
    SIZE=$(du -h "$FILENAME" | cut -f1)
    echo "📏 File size: $SIZE"
else
    echo "❌ Custom APK tidak ditemukan!"
fi

echo ""
echo "🎉 Done! Ready for distribution."
