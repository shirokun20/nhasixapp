#!/bin/bash
# Config Validation Script
# Validates all JSON config files

echo "🔍 Validating NhasixApp Config Files..."
echo ""

CONFIGS_DIR="$(dirname "$0")"
HAS_ERROR=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to validate JSON
validate_json() {
    local file=$1
    local filename=$(basename "$file")
    
    echo -n "  Checking $filename... "
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}[MISSING]${NC}"
        HAS_ERROR=1
        return
    fi
    
    # Try to parse JSON with python
    if command -v python3 &> /dev/null; then
        if python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
            echo -e "${GREEN}[OK]${NC}"
        else
            echo -e "${RED}[INVALID JSON]${NC}"
            python3 -c "import json; json.load(open('$file'))" 2>&1 | head -5
            HAS_ERROR=1
        fi
    # Fallback to jq if available
    elif command -v jq &> /dev/null; then
        if jq empty "$file" 2>/dev/null; then
            echo -e "${GREEN}[OK]${NC}"
        else
            echo -e "${RED}[INVALID JSON]${NC}"
            jq empty "$file" 2>&1
            HAS_ERROR=1
        fi
    else
        echo -e "${YELLOW}[SKIPPED - no validator]${NC}"
        echo "    Install python3 or jq to enable validation"
    fi
}

# Validate all config files
echo "📋 Core Configs:"
validate_json "$CONFIGS_DIR/version.json"
validate_json "$CONFIGS_DIR/app-config.json"
validate_json "$CONFIGS_DIR/tags-config.json"

echo ""
echo "🌐 Source Configs:"
validate_json "$CONFIGS_DIR/nhentai-config.json"
validate_json "$CONFIGS_DIR/crotpedia-config.json"

echo ""
if [ $HAS_ERROR -eq 0 ]; then
    echo -e "${GREEN}✅ All configs are valid!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some configs have errors. Please fix them.${NC}"
    exit 1
fi
