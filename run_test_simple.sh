#!/bin/bash

echo "🧪 Running Simple Download Test (No Service Locator)..."

# Clean and get dependencies
echo "📦 Getting dependencies..."
flutter clean
flutter pub get

# Run simple test without service locator
echo "🚀 Running test without GetIt dependency..."
flutter run test_download_simple.dart --debug

echo "✅ Simple test launched!"
echo ""
echo "📋 This test uses manual dependency injection instead of GetIt"
echo "📋 Should avoid 'Object/factory not registered' errors"
echo ""
echo "🧪 Test Steps:"
echo "1. Test Notification - Should work without GetIt errors"
echo "2. Test Download - Should download 3 images"
echo "3. Check Files - Should show downloaded files"
echo "4. Test PDF - Should create PDF from images"
echo ""
echo "📁 Expected files: /storage/emulated/0/Download/nhasix/590111/"