#!/bin/bash

# Quick Flutter Run Commands
# Usage: ./run_quick.sh [mode]

MODE=${1:-help}

case $MODE in
    "dev"|"d")
        echo "🔧 Quick Development Run (Hot Reload + Optimized)"
        fvm flutter run --enable-impeller
        ;;
    "test"|"t")
        echo "⚡ Performance Testing Run"
        fvm flutter run --profile
        ;;
    "prod"|"p")
        echo "🚀 Production Testing Run"
        fvm flutter run --release
        ;;
    "debug")
        echo "🐛 Full Debug Run"
        fvm flutter run
        ;;
    *)
        echo "🚀 Flutter Run Quick Commands"
        echo ""
        echo "Usage: ./run_quick.sh [mode]"
        echo ""
        echo "Available modes:"
        echo "  dev, d     🔧 Development (hot reload + optimized)"
        echo "  test, t    ⚡ Performance testing (profile mode)" 
        echo "  prod, p    🚀 Production testing (release mode)"
        echo "  debug      🐛 Full debug mode"
        echo ""
        echo "Examples:"
        echo "  ./run_quick.sh dev    # Most common for development"
        echo "  ./run_quick.sh test   # For performance testing"
        echo "  ./run_quick.sh prod   # Final validation"
        echo ""
        echo "💡 For detailed options, use: ./run_optimized.sh"
        ;;
esac
