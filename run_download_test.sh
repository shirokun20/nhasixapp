#!/bin/bash

# Script untuk menjalankan test download
echo "🚀 Starting Download Test..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi

# Clean and get dependencies
echo "📦 Getting dependencies..."
flutter clean
flutter pub get

# Check for connected device
echo "📱 Checking for connected device..."
flutter devices

# Build and run test app
echo "🔨 Building and running test app..."
flutter run test_main.dart --debug

echo "✅ Test app launched!"
echo ""
echo "📋 Test Instructions:"
echo "1. Tap 'Download Images Only' to test basic download"
echo "2. Tap 'Download as PDF' to test PDF conversion"
echo "3. Tap 'Test Services' to test individual services"
echo "4. Check notifications for download progress"
echo "5. Check /storage/emulated/0/Download/nhasix/ for downloaded files"
echo ""
echo "🔍 Troubleshooting:"
echo "- If permissions denied: Grant storage permissions in app settings"
echo "- If notifications not showing: Grant notification permissions"
echo "- If download fails: Check network connection and URL accessibility"