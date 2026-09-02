#!/bin/bash

# Script untuk optimize tags.json yang 4.9MB
# Usage: ./scripts/optimize_assets.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

echo "🔍 APK Size Optimization - Asset Analysis"
echo ""

# Check current asset sizes
echo "📊 Current Asset Sizes:"
find assets/ -type f -exec du -h {} + | sort -hr | head -10

echo ""
echo "🚨 PROBLEM IDENTIFIED:"
echo "📄 assets/json/tags.json = 4.9MB (Too big!)"
echo ""

# Create backup
echo "💾 Creating backup..."
cp assets/json/tags.json assets/json/tags.json.backup

# Show first few lines to understand structure
echo "🔍 File structure analysis:"
echo "First few lines of tags.json:"
head -n 10 assets/json/tags.json

echo ""
echo "📏 File statistics:"
echo "Lines: $(wc -l < assets/json/tags.json)"
echo "Size: $(du -h assets/json/tags.json | cut -f1)"
echo "Characters: $(wc -c < assets/json/tags.json)"

echo ""
echo "💡 OPTIMIZATION OPTIONS:"
echo ""
echo "Option 1: 🗜️ COMPRESS JSON (Recommended)"
echo "  - Use gzip compression"
echo "  - Load and decompress at runtime"
echo "  - Expected size: ~500KB-1MB (80-90% reduction)"
echo ""
echo "Option 2: 🌐 MOVE TO NETWORK"
echo "  - Remove from assets bundle"
echo "  - Fetch from API when needed"
echo "  - Cache locally for offline use"
echo "  - Expected size: 0KB in APK"
echo ""
echo "Option 3: ✂️ SPLIT INTO CHUNKS"
echo "  - Break into smaller category files"
echo "  - Load categories on demand"
echo "  - Expected size: Load only what's needed"
echo ""
echo "Option 4: 🔧 BINARY FORMAT"
echo "  - Convert to protobuf/msgpack"
echo "  - Expected size: ~1-2MB (60-80% reduction)"

echo ""
echo "🎯 RECOMMENDATION:"
echo "Use Option 1 (Compression) for immediate 80-90% size reduction!"
echo ""

# Ask user for action
read -p "Apply compression optimization? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗜️ Compressing tags.json..."
    
    # Compress using gzip
    gzip -k assets/json/tags.json
    
    # Show results
    original_size=$(du -h assets/json/tags.json | cut -f1)
    compressed_size=$(du -h assets/json/tags.json.gz | cut -f1)
    
    echo "✅ Compression completed!"
    echo "📊 Results:"
    echo "  Original: $original_size"
    echo "  Compressed: $compressed_size"
    
    # Calculate compression ratio
    original_bytes=$(wc -c < assets/json/tags.json)
    compressed_bytes=$(wc -c < assets/json/tags.json.gz)
    ratio=$(echo "scale=1; $compressed_bytes * 100 / $original_bytes" | bc)
    savings=$(echo "scale=1; 100 - $ratio" | bc)
    
    echo "  Compression ratio: ${ratio}%"
    echo "  Space savings: ${savings}%"
    echo ""
    echo "📝 TODO: Update code to load compressed JSON:"
    echo "  1. Read tags.json.gz instead of tags.json"
    echo "  2. Decompress using gzip decoder"
    echo "  3. Parse JSON as normal"
    echo ""
    echo "🚀 Expected APK size reduction: ~4MB!"
else
    echo "❌ Optimization skipped."
fi

echo ""
echo "📱 NEXT STEPS:"
echo "1. 🗜️ Implement compressed JSON loading (if chosen)"
echo "2. 🏗️ Build with optimized script: ./scripts/build_optimized.sh"
echo "3. 📏 Verify APK size reduction"
echo "4. 🧪 Test app functionality"
echo ""
echo "🎉 After optimization, expect APK size: 6-8MB instead of 29MB!"
