#!/bin/bash

echo "🧪 Running Simple Download Test..."

# Clean and get dependencies
echo "📦 Getting dependencies..."
flutter clean
flutter pub get

# Run simple test
echo "🚀 Running simple test app..."
flutter run test_download_only.dart --debug

echo "✅ Simple test launched!"
echo ""
echo "📋 Test Steps:"
echo "1. Tap 'Test Notification' - Should show notification without error"
echo "2. Tap 'Test Download' - Should download 3 images"
echo "3. Tap 'Check Downloaded Files' - Should show downloaded files"
echo "4. Tap 'Test PDF Conversion' - Should create PDF from images"
echo ""
echo "📁 Expected files in: /storage/emulated/0/Download/nhasix/590111/"