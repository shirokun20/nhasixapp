#!/bin/bash

# Debug script to test if Crotpedia form mode is working

echo "🔍 Checking SearchMode Configuration..."
echo ""

# 1. Check if config file has correct searchMode
echo "1️⃣ Config File Check:"
grep -n "searchMode" configs/crotpedia-config.json
echo ""

# 2. Check if generated code is up to date
echo "2️⃣ Generated Files Status:"
ls -la lib/core/config/*.g.dart lib/core/config/*.freezed.dart 2>/dev/null || echo "No generated files found"
echo ""

# 3. Run flutter analyze to check for errors
echo "3️⃣ Running Flutter Analyze on search screen..."
flutter analyze lib/presentation/pages/search/search_screen.dart lib/presentation/pages/search/form_based_search_widget.dart
echo ""

# 4. Check for SearchMode usage in code
echo "4️⃣ SearchMode Usage Check:"
grep -rn "SearchMode.formBased" lib/presentation/pages/search/
echo ""

# 5. Check RemoteConfigService
echo "5️⃣ RemoteConfigService Check:"
grep -n "getConfig" lib/core/config/remote_config_service.dart | head -5
echo ""

echo "✅ Debug checks complete!"
echo ""
echo "📝 Next Steps:"
echo "   1. Run app: flutter run --debug"
echo "   2. Switch to Crotpedia source"
echo "   3. Navigate to search screen"
echo "   4. Check if form appears"
echo "   5. Check logs for: 'Search mode:' or 'searchMode'"
