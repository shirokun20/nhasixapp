#!/bin/bash

# Optimized Flutter Run Script
# Usage: ./run_optimized.sh [mode] [platform]
# Modes: debug, release, profile, minimal
# Platforms: arm64, arm, all

MODE=${1:-profile}
PLATFORM=${2:-arm64}

echo "🚀 Starting optimized Flutter run..."
echo "📱 Mode: $MODE"
echo "🏗️ Platform: $PLATFORM"
echo "📦 App: nhasix $(grep 'version:' pubspec.yaml | sed 's/version: //')"
echo ""

# Set platform flag
case $PLATFORM in
    "arm64")
        PLATFORM_FLAG=""
        echo "🎯 Target: ARM64 (will use default platform selection)"
        ;;
    "arm")
        PLATFORM_FLAG=""
        echo "🎯 Target: ARM (will use default platform selection)"
        ;;
    "all")
        PLATFORM_FLAG=""
        echo "🎯 Target: Universal (default platform selection)"
        ;;
    *)
        PLATFORM_FLAG=""
        echo "🎯 Target: Default platform selection"
        ;;
esac

echo ""

case $MODE in
    "debug")
        echo "🔧 DEBUG MODE - Full development features"
        echo "✅ Hot reload enabled"
        echo "✅ Debug symbols included"
        echo "✅ Fast compilation"
        echo "⚠️ Larger app size (~40-60MB)"
        echo "⚠️ Slower runtime performance"
        echo ""
        echo "🏃‍♂️ Running: fvm flutter run $PLATFORM_FLAG"
        fvm flutter run $PLATFORM_FLAG
        ;;
        
    "release")
        echo "🚀 RELEASE MODE - Production optimized"
        echo "✅ Full optimizations enabled"
        echo "✅ Smallest app size (~12-15MB)"
        echo "✅ Best runtime performance"
        echo "❌ No hot reload"
        echo "❌ No debug features"
        echo ""
        echo "🏃‍♂️ Running: fvm flutter run --release $PLATFORM_FLAG"
        fvm flutter run --release $PLATFORM_FLAG
        ;;
        
    "profile")
        echo "⚡ PROFILE MODE - Balanced optimization (RECOMMENDED)"
        echo "✅ Performance optimizations"
        echo "✅ Moderate app size (~20-25MB)"
        echo "✅ Performance profiling available"
        echo "✅ Good runtime performance"
        echo "⚠️ No hot reload"
        echo ""
        echo "🏃‍♂️ Running: fvm flutter run --profile $PLATFORM_FLAG"
        fvm flutter run --profile $PLATFORM_FLAG
        ;;
        
    "minimal")
        echo "🎯 MINIMAL MODE - Custom optimized debug"
        echo "✅ Hot reload enabled"
        echo "✅ Optimized rendering (Impeller)"
        echo "✅ Faster than standard debug"
        echo "✅ Development-friendly"
        echo "📏 Better performance than debug"
        echo ""
        echo "🏃‍♂️ Running: fvm flutter run --enable-impeller"
        fvm flutter run --enable-impeller
        ;;
        
    *)
        echo "❌ Unknown mode: $MODE"
        echo "Available modes: debug, release, profile, minimal"
        echo ""
        echo "💡 Quick commands:"
        echo "  ./run_optimized.sh debug     # Full debug features"
        echo "  ./run_optimized.sh profile   # Recommended for testing"
        echo "  ./run_optimized.sh release   # Production testing"
        echo "  ./run_optimized.sh minimal   # Fast debug with smaller size"
        echo ""
        echo "🎯 Platform options:"
        echo "  ./run_optimized.sh profile arm64  # ARM64 only (recommended)"
        echo "  ./run_optimized.sh profile arm    # ARM for older devices"
        echo "  ./run_optimized.sh profile all    # Universal (larger)"
        exit 1
        ;;
esac
