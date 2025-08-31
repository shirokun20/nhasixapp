# 🎨 Theme Update Plan - Widget Theming Standardization

## 📋 Overview

This document outlines a comprehensive plan to update all widgets and screens in the NhaSixApp to consistently use the established theme constants from `lib/core/constants/`. The goal is to eliminate hardcoded colors and text styles and ensure a cohesive design system throughout the application.

## 🔍 Current State Analysis

### ✅ Tema Constants Available
- **ColorsConst**: Comprehensive color palette with dark theme colors, semantic colors, status colors, and utility methods
- **TextStyleConst**: Complete text style system with semantic styles and component-specific styles
- **ThemeState**: Material 3 theme implementation with proper ColorScheme integration

### ✅ Already Properly Themed (Using Material 3 + TextStyleConst)
**Screens:**
- `settings_screen.dart` ✅ - Fully themed with Theme.of(context).colorScheme + TextStyleConst
- `content_by_tag_screen.dart` ✅ - Well themed with Material 3 approach
- `main_screen_scrollable.dart` ✅ - Mostly themed (minor hardcoded fontWeight remains)
- `detail_screen.dart` ✅ - Partially themed (some hardcoded values remain)

**Widgets:**
- `selected_filters_widget.dart` ✅ - Uses ColorsConst and TextStyleConst extensively
- `filter_item_card_widget.dart` ✅ - Mixed Theme.of(context) + ColorsConst approach
- `filter_data_search_widget.dart` ✅ - Well themed with Material 3 approach
- `download_stats_widget.dart` ✅ - Mixed but properly themed
- `content_list_widget.dart` ✅ - Partially themed

### ❌ Needs Theming Updates (Still using hardcoded values)
**High Priority - No Theme.of(context) usage:**
- `progressive_image_widget.dart` ❌ - Hardcoded Colors.black, Colors.white
- `app_scaffold_with_offline.dart` ❌ - Multiple Colors.orange[xxx] hardcoded
- `offline_indicator_widget.dart` ❌ - Hardcoded font weights and sizes

**Medium Priority - Partially themed:**
- `search_screen.dart` - Some hardcoded values remain
- `downloads_screen.dart` - Some hardcoded font weights
- `splash_screen.dart` - Multiple hardcoded text styles
- `favorites_screen.dart` - Some hardcoded overlay colors
- `reader_screen.dart` - Hardcoded font sizes

---

## 🎯 Priority Levels

### **Current Theming Approaches in the App:**
The app currently uses two valid theming approaches:
1. **Material 3 + TextStyleConst** (Preferred) - Using `Theme.of(context).colorScheme` + `TextStyleConst`
2. **Direct Constants** - Using `ColorsConst` + `TextStyleConst` directly

**Reference Implementation:** `settings_screen.dart` demonstrates the preferred Material 3 approach.

### Priority 1 (High) - Widgets with No Theming
Widgets still using completely hardcoded values without any theme integration.

### Priority 2 (Medium) - Widgets with Partial Theming  
Widgets using some theme integration but still having hardcoded values.

### Priority 3 (Low) - Minor Theming Improvements
Widgets that are mostly themed but need minor consistency updates.

---

## 📱 Widgets Requiring Updates

### Priority 1 - Widgets with No Theming (Critical)

## Priority 1: Critical UI Components (COMPLETED ✅)
### Status: ✅ FULLY THEME-AWARE

#### 1. Progressive Image Widget ✅
- **File**: `lib/presentation/widgets/progressive_image_widget.dart`
- **Status**: ✅ **COMPLETED** - Fully refactored to use theme-aware colors
- **Updates Made**:
  - Shimmer placeholder: `Theme.of(context).colorScheme.surfaceVariant`
  - Error widgets: `Theme.of(context).colorScheme.surfaceVariant` background, `onSurfaceVariant` for icons/text
  - Loading indicators: `Theme.of(context).colorScheme.primary`
  - Offline badge: `Theme.of(context).colorScheme.tertiary` with `onTertiary` text
  - All text colors: `Theme.of(context).colorScheme.onSurface` or `onSurfaceVariant`
  - Removed unused `ColorsConst` import
- **Theme Responsiveness**: ✅ Fully responsive to theme changes

#### 2. App Scaffold with Offline ✅  
- **File**: `lib/presentation/widgets/app_scaffold_with_offline.dart`
- **Status**: ✅ **COMPLETED** - Fully refactored to use theme-aware colors
- **Updates Made**:
  - Replaced `Colors.orange[xxx]` with `Theme.of(context).colorScheme.error` variants
  - Updated hardcoded `TextStyle()` with `TextStyleConst` semantic styles
  - Offline state colors now use theme system
  - Follows Material 3 approach
- **Theme Responsiveness**: ✅ Fully responsive to theme changes

#### 3. Offline Indicator Widget ✅
- **File**: `lib/presentation/widgets/offline_indicator_widget.dart`
- **Status**: ✅ **COMPLETED** - Fully refactored to use theme-aware colors
- **Updates Made**:
  - Connection colors: `Theme.of(context).colorScheme.error` (offline), `tertiary` (wifi/ethernet), `secondary` (mobile), `primary` (other)
  - Background colors: `errorContainer` for offline banner, `surfaceVariant` for toggle
  - Text colors: `onErrorContainer`, `onSurfaceVariant`
  - Switch colors: `tertiary` for active state
  - Border colors: `outline` and semantic colors
  - Removed unused `ColorsConst` import
- **Theme Responsiveness**: ✅ Fully responsive to theme changes

#### 4. Filter Widgets ✅
- **Files**: 
  - `lib/presentation/widgets/filter_data_search_widget.dart`
  - `lib/presentation/widgets/filter_item_card_widget.dart`
- **Status**: ✅ **COMPLETED** - Fully refactored to use theme-aware colors
- **Updates Made**:
  - Search widget: `Theme.of(context).colorScheme.surfaceVariant` background, `primary` for focus states
  - Filter cards: `primary`/`error` for include/exclude states, semantic background colors
  - Text colors: `onSurfaceVariant`, `onSurface`
  - Border and action button colors: semantic theme colors
  - Removed unused `ColorsConst` imports
- **Theme Responsiveness**: ✅ Fully responsive to theme changes

#### 5. Selected Filters Widget ✅
- **File**: `lib/presentation/widgets/selected_filters_widget.dart`
- **Status**: ✅ **COMPLETED** - Fully refactored to use theme-aware colors
- **Updates Made**:
  - Filter chips: `Theme.of(context).colorScheme.primary`/`error` for include/exclude states
  - Background colors: `surfaceVariant` for "more" indicator
  - Text and icon colors: semantic theme colors based on filter state
  - Border colors: dynamic opacity-based theme colors
  - Both regular and compact versions updated
  - Removed unused `ColorsConst` import
- **Theme Responsiveness**: ✅ Fully responsive to theme changes

#### 6. `main_screen_scrollable.dart` ⚠️
**Current Status:** Already using Theme.of(context).colorScheme extensively ✅
**Remaining Issues:**
- Some hardcoded `fontWeight: FontWeight.w500/w600`

**Action Items:**
- [ ] Replace remaining hardcoded font weights with `TextStyleConst` styles
- [ ] Ensure consistency with existing theme usage

#### 7. `detail_screen.dart` ⚠️
**Current Status:** Partially themed with Theme.of(context) ✅
**Remaining Issues:**  
- Some hardcoded font weights
- `Colors.transparent` usage in gradients

**Action Items:**
- [ ] Replace remaining hardcoded font weights with `TextStyleConst` styles
- [ ] Review gradient usage for theme consistency

#### 6. `content_list_widget.dart` ⚠️
**Current Status:** Uses Theme.of(context).colorScheme.onSurface ✅
**Remaining Issues:**
- Hardcoded `TextStyle(fontSize: 64)` for empty state

**Action Items:**
- [ ] Create appropriate large icon style in TextStyleConst
- [ ] Replace hardcoded large font size

### Priority 3 - Minor Improvements (Optional)

#### 7. `filter_item_card_widget.dart` ⚠️
**Current Status:** Mixed Theme.of(context) + ColorsConst approach ✅
**Note:** This widget is actually well-themed, using both approaches appropriately

**Action Items:**
- [ ] Verify consistency between approaches
- [ ] Document why mixed approach is used (tag colors, etc.)

#### 8. `download_stats_widget.dart` ⚠️  
**Current Status:** Well themed with Theme.of(context).colorScheme ✅
**Minor Issues:** Some hardcoded font weights remain

**Action Items:**
- [ ] Replace any remaining hardcoded font weights with TextStyleConst

---

## 📱 Screens Requiring Updates

### Priority 1 - Screens with Partial Theming

#### 1. `search_screen.dart` ⚠️
**Expected Issues:**
- Some hardcoded font weights and sizes
- Possible `Colors.transparent` usage
- Inconsistent button styling

**Action Items:**
- [ ] Audit current theming status
- [ ] Replace hardcoded text styles with `TextStyleConst` + Material 3 approach
- [ ] Follow settings_screen.dart pattern for consistency

#### 2. `downloads_screen.dart` ⚠️
**Known Issues:**
- Hardcoded `fontWeight: FontWeight.bold/w500`

**Action Items:**
- [ ] Replace hardcoded font weights with `TextStyleConst` styles
- [ ] Ensure download status indicators use theme colors
- [ ] Apply Material 3 theming pattern

#### 3. `splash_screen.dart` ⚠️
**Known Issues:**
- Multiple hardcoded font weights and sizes
- Inconsistent text styling

**Action Items:**
- [ ] Replace all hardcoded text styles with `TextStyleConst`
- [ ] Ensure brand elements align with theme
- [ ] Apply consistent theming approach

#### 4. `favorites_screen.dart` ⚠️
**Known Issues:**
- Hardcoded `Colors.black.withValues(alpha: 0.3)` for overlays

**Action Items:**
- [ ] Replace hardcoded overlay colors with theme alternatives
- [ ] Follow Material 3 + TextStyleConst pattern

#### 5. `reader_screen.dart` ⚠️
**Known Issues:**
- Hardcoded font sizes and weights

**Action Items:**
- [ ] Apply reading-appropriate text styles from theme
- [ ] Ensure UI overlays use theme colors

### ✅ Already Well Themed Screens

#### `settings_screen.dart` ✅
**Status:** Perfect example of Material 3 + TextStyleConst integration
**Features:**
- Uses `Theme.of(context).colorScheme` for all colors
- Uses `TextStyleConst` for all text styles
- Consistent theming throughout
- **Use as reference for other screens**

#### `content_by_tag_screen.dart` ✅
**Status:** Well themed with Material 3 approach
**Features:**
- Extensive use of `Theme.of(context).colorScheme`
- Good integration with theme system

#### `main_screen_scrollable.dart` ✅
**Status:** Mostly themed, minor improvements needed
**Features:**
- Good use of `Theme.of(context).colorScheme`
- Minor hardcoded font weights remain

#### `detail_screen.dart` ✅  
**Status:** Partially themed, some cleanup needed
**Features:**
- Uses `Theme.of(context).colorScheme` in many places
- Some hardcoded values remain

---

## 🛠️ Implementation Strategy

### Phase 1: Core Infrastructure (Week 1)
1. **Enhance ColorsConst**
   - Add missing semantic colors (offline indicators, overlays)
   - Add utility methods for common color operations
   - Document usage patterns

2. **Enhance TextStyleConst**
   - Add missing semantic styles (icons, overlays, special cases)
   - Add utility methods for common style operations
   - Document usage patterns

### Phase 2: Core Widgets (Week 2)
1. Update Priority 1 widgets
2. Test theme consistency
3. Update documentation

### Phase 3: Screens (Week 3)
1. Update Priority 1 screens
2. Update Priority 2 screens
3. Ensure consistent user experience

### Phase 4: Polish & Testing (Week 4)
1. Update remaining widgets
2. Comprehensive testing
3. Theme switching verification
4. Documentation updates

---

## 🔧 Technical Implementation Guidelines

### Color Usage Patterns (Material 3 Approach - Preferred)
```dart
// ❌ Don't do this
color: Color(0xFF1F1F1F)
color: Colors.blue
color: Colors.black.withOpacity(0.3)

// ✅ Do this (Material 3 + Theme integration)
color: Theme.of(context).colorScheme.surface
color: Theme.of(context).colorScheme.primary  
color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)

// ✅ Alternative approach (Direct constants)
color: ColorsConst.darkBackground
color: ColorsConst.accentBlue
color: ColorsConst.darkBackground.withValues(alpha: 0.3)
```

### Text Style Usage Patterns
```dart
// ❌ Don't do this
style: TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: Colors.white,
)

// ✅ Do this (Material 3 + TextStyleConst - Preferred)
style: TextStyleConst.headingSmall.copyWith(
  color: Theme.of(context).colorScheme.onSurface,
)

// ✅ Alternative approach
style: TextStyleConst.headingSmall.copyWith(
  color: ColorsConst.darkTextPrimary,
)
```

### Reference Implementation Pattern (settings_screen.dart)
```dart
// Follow this pattern for consistency
Text(
  'Title Text',
  style: TextStyleConst.headingSmall.copyWith(
    color: Theme.of(context).colorScheme.primary,
  ),
),

Container(
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    border: Border.all(
      color: Theme.of(context).colorScheme.outline,
    ),
  ),
  child: Text(
    'Content',
    style: TextStyleConst.bodyLarge.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
    ),
  ),
),
```

---

## 📊 Progress Tracking

## 📊 Progress Tracking

### ✅ Already Completed (Well Themed) - 6/6 ✅
**Priority 1 Widgets - COMPLETED:**
- [x] **Progressive Image Widget** ✅ (Shimmer, error states, loading indicators)
- [x] **App Scaffold with Offline** ✅ (Orange colors → theme colors) 
- [x] **Offline Indicator Widget** ✅ (Connection states, banners, toggles)
- [x] **Filter Data Search Widget** ✅ (Search input, focus states)
- [x] **Filter Item Card Widget** ✅ (Include/exclude states, borders)
- [x] **Selected Filters Widget** ✅ (Filter chips, remove buttons)

**Screens:**
- [x] **Settings Screen** ✅ (Perfect reference implementation)
- [x] **Content by Tag Screen** ✅ (Well themed)

### ✅ CRITICAL PRIORITY - Widgets/Screens COMPLETED (2/15 completed)

**🔥 HIGHEST IMPACT (Main UI Components):**
- [x] **Content Card Widget** ✅ (COMPLETED - Fully refactored to use theme-aware colors)
- [x] **Modern Pagination Widget** ✅ (COMPLETED - Fully refactored to use Material 3 + TextStyleConst)
  - **Status**: ✅ **COMPLETED** - Fully refactored to use Material 3 + TextStyleConst approach  
  - **Updates Made**:
    - Dialog colors: `surfaceContainer` for background, `onSurface` for titles, `onSurfaceVariant` for descriptions
    - Input field: `surface` for background, `outline` for borders, `primary` for focus states
    - Button colors: `primary`/`onPrimary` for elevated buttons, `onSurfaceVariant` for text buttons
    - SnackBar: `error`/`onError` for error messages
    - Container: `surface` for main background, `surfaceContainer` for cards, `outline` for borders
    - Text colors: `onSurface` for primary text, `onSurfaceVariant` for secondary text
    - Icon states: `onSurface` for enabled, `onSurfaceVariant` for disabled
    - Removed unused `ColorsConst` import
  - **Theme Responsiveness**: ✅ Fully responsive to theme changes
  - **Status**: ✅ **COMPLETED** - Fully refactored to use Material 3 + TextStyleConst approach
  - **Updates Made**:
    - Card colors: `Theme.of(context).colorScheme.surfaceContainer` for card background
    - Shadow colors: `Theme.of(context).colorScheme.shadow` for card shadow
    - Interactive colors: `Theme.of(context).colorScheme.primary` for splash, `surfaceVariant` for highlights
    - Text colors: `onSurface`, `onSurfaceVariant` for various text elements
    - Image states: `surfaceVariant` for placeholders and errors
    - Progress indicators: `primary` for loading, `surface` for overlay backgrounds
    - Badge colors: `surface` for page count, `tertiary` for offline indicators
    - Artist text: `primary` for artist names
    - Tag colors: Dynamic theme-based mapping (primary/secondary/tertiary/error/inversePrimary/outline)
    - Favorite buttons: `error` for active favorites, `onSurface` for inactive
    - Language flags: `outline` for borders, `surfaceVariant` for error states
    - Static method: Added required `context` parameter for theme access
    - Removed unused `ColorsConst` import
  - **Theme Responsiveness**: ✅ Fully responsive to theme changes
  - **Breaking Changes**: Static `buildImage()` method now requires `context` parameter (fixed in favorites_screen.dart)

**🔥 HIGH IMPACT (Still Pending - Large Complex Files):**
- [ ] **Detail Screen** (15/100+ tasks) - ~85+ remaining instances, PARTIALLY STARTED
  - **Status**: ⚠️ **PARTIALLY STARTED** - Started Material 3 conversion, ~15% completed  
  - **Progress Made**: Removed ColorsConst import, converted SliverAppBar, offline banner, title section, and image placeholders
  - **Remaining**: ~85+ ColorsConst instances including tag colors, download info sections, progress indicators, dialog components
  - **Challenge**: Very large file with complex nested UI components, estimated 4-6 hours for complete conversion
  - **Recommendation**: Complete in separate focused session due to size and complexity  
- [ ] **Search Screen** (0/99 tasks) - **MASSIVE FILE** - 1210 lines, 99 ColorsConst instances, search functionality
  - **Status**: ❌ **NEEDS DEDICATED SESSION** - File too large and complex for current session
  - **Challenge**: Extremely large file (1210 lines) with extensive UI components, estimated 6-8 hours for complete conversion
  - **Recommendation**: Tackle in separate dedicated session due to massive scope
- [ ] **Favorites Screen** (0/73 tasks) - **LARGE FILE** - 810 lines, 73 ColorsConst instances, favorites management  
  - **Status**: ❌ **NEEDS DEDICATED SESSION** - File too large and complex for current session
  - **Challenge**: Large file (810 lines) with complex UI components, estimated 4-5 hours for complete conversion
  - **Recommendation**: Tackle in separate dedicated session after search screen
- [x] **Downloads Screen** (6/6 tasks) - ✅ COMPLETED - All ColorsConst replaced with theme

**🔥 HIGH IMPACT (Core Widgets):**
- [x] **Download Item Widget** (6/6 tasks) - ✅ COMPLETED - All ColorsConst replaced with theme
- [x] **Download Range Selector Widget** (6/6 tasks) - ✅ COMPLETED - All ColorsConst replaced with theme
- [x] **Progress Indicator Widget** (4/4 tasks) - ✅ COMPLETED - All ColorsConst replaced with theme
- [x] **Filter Type Tab Bar Widget** (4/4 tasks) - ✅ COMPLETED - All ColorsConst replaced with theme
- [x] **Download Button Widget** (4/4 tasks) - ✅ COMPLETED - All ColorsConst replaced with theme
- [x] **Offline Content Screen** (4/4 tasks) - ✅ COMPLETED - All ColorsConst replaced with theme

**🟡 MEDIUM IMPACT (Supporting Components):**
- [x] **Error Widget** (2/2 tasks) - ✅ COMPLETED - All hardcoded Colors.orange/red replaced with theme
- [x] **Platform Not Supported Dialog** (1/1 tasks) - ✅ COMPLETED - Colors.orange replaced with theme
- [x] **Widget Examples** (1/1 tasks) - ✅ COMPLETED - All hardcoded colors replaced with theme

### 📈 **Updated Progress Summary:**
- **Total Components**: 21 (12 completed + 9 pending)
- **Completion Rate**: 12/21 = **57.1% completed**  
- **Large Complex Files Remaining**: 3 files (Detail, Search, Favorites) with **257+ ColorsConst instances**
- **Quick Wins Completed**: All small/medium components finished
- **Status**: **Ready for large file dedicated sessions**
- **Estimated Effort**: ~15-20 hours for remaining large files (requires separate focused sessions)

### 🎯 **Recommended Priority Order:**
1. **Week 1**: Content Card Widget, Detail Screen (highest user impact)
2. **Week 2**: Search Screen, Favorites Screen, Downloads Screen (core functionality)
3. **Week 3**: Major widgets (Modern Pagination, Download widgets, Progress indicators)
4. **Week 4**: Remaining widgets + testing and polish

### ❌ HIGH PRIORITY - Widgets/Screens Still Using ColorsConst (0/15 completed)

**CRITICAL IMPACT - Main User Interface Components:**

#### 1. Content Card Widget ❌ (HIGHEST PRIORITY)
- **File**: `lib/presentation/widgets/content_card_widget.dart`
- **Status**: ❌ **MASSIVE ColorsConst usage** - (~40+ instances)
- **Current Issues**:
  - Card backgrounds: `ColorsConst.darkCard`, `darkElevated`, `darkBackground`
  - Interaction colors: `ColorsConst.accentBlue`, `hoverColor`, `splashColor`
  - Text colors: `darkTextPrimary`, `darkTextSecondary`, `darkTextTertiary`
  - Tag colors: `getTagColor()` method calls throughout
  - Border colors: `borderMuted`, `borderDefault`
- **Impact**: 🔥 **CRITICAL** - Main content display across entire app

#### 2. Download Button Widget ❌
- **File**: `lib/presentation/widgets/download_button_widget.dart`
- **Status**: ❌ **NEEDS UPDATE** - (~15+ instances)
- **Current Issues**:
  - State colors: `ColorsConst.accentGreen`, `warning`, `success`, `error`, `info`
  - Button colors: `primary` for default states
  - Progress indicators use hardcoded colors
- **Impact**: 🔥 **HIGH** - Download functionality throughout app

#### 3. Download Item Widget ❌
- **File**: `lib/presentation/widgets/download_item_widget.dart`
- **Status**: ❌ **EXTENSIVE usage** - (~25+ instances)
- **Current Issues**:
  - Surface colors: `ColorsConst.surface`, background colors
  - Text colors: `onSurface` variations with alpha
  - Status colors: `error`, `success`, `primary`, `warning`
  - Interactive colors for buttons and actions
- **Impact**: 🔥 **HIGH** - Download list interface

#### 4. Modern Pagination Widget ❌
- **File**: `lib/presentation/widgets/modern_pagination_widget.dart`
- **Status**: ❌ **MASSIVE usage** - (~25+ instances)
- **Current Issues**:
  - Background colors: `darkCard`, `darkBackground`, `darkSurface`
  - Text colors: `darkTextPrimary`, `darkTextSecondary`, `darkTextTertiary`
  - Accent colors: `accentBlue`, `accentRed` for states
  - Border colors: `borderDefault` throughout
- **Impact**: 🔥 **HIGH** - Navigation component

#### 5. Download Range Selector Widget ❌
- **File**: `lib/presentation/widgets/download_range_selector.dart`
- **Status**: ❌ **EXTENSIVE usage** - (~20+ instances)
- **Current Issues**:
  - Card colors: `darkCard`, `darkBackground`
  - Slider colors: `accentBlue` for active states
  - Text colors: `darkTextPrimary`, `darkTextSecondary`
  - Border colors: `borderDefault`
- **Impact**: 🔥 **HIGH** - Range selection interface

#### 6. Progress Indicator Widget ❌
- **File**: `lib/presentation/widgets/progress_indicator_widget.dart`
- **Status**: ❌ **EXTENSIVE usage** - (~15+ instances)
- **Current Issues**:
  - Background colors: `darkElevated`, `darkCard`, `darkBackground`
  - Progress colors: `accentBlue` as default
  - Text colors: `darkTextSecondary`
  - Border colors: `borderMuted`
- **Impact**: 🔥 **HIGH** - Progress feedback across app

#### 7. Filter Type Tab Bar Widget ❌
- **File**: `lib/presentation/widgets/filter_type_tab_bar_widget.dart`
- **Status**: ❌ **SIGNIFICANT usage** - (~15+ instances)
- **Current Issues**:
  - Tab colors: `darkSurface`, `darkCard`
  - Selected state: `accentBlue` for active tabs
  - Text colors: `darkTextPrimary`, `darkTextSecondary`
  - Border colors: `borderDefault`
- **Impact**: 🔥 **HIGH** - Filter navigation

**CRITICAL IMPACT - Main Screens:**

#### 8. Detail Screen ❌ (PARTIALLY DONE)
- **File**: `lib/presentation/pages/detail/detail_screen.dart`
- **Status**: ⚠️ **PARTIALLY UPDATED** - (~50+ remaining instances)
- **Current Issues**:
  - Background colors: `darkSurface`, `darkCard`, `darkBackground`
  - Accent colors: `accentYellow`, `accentBlue`, `accentGreen`, etc.
  - Text colors: All dark text variants
  - FloatingActionButton colors still hardcoded
- **Impact**: 🔥 **CRITICAL** - Main content detail view

#### 9. Downloads Screen ❌
- **File**: `lib/presentation/pages/downloads/downloads_screen.dart`
- **Status**: ❌ **EXTENSIVE usage** - (~30+ instances)
- **Current Issues**:
  - Background colors: `background`, `surface`
  - Text colors: `onSurface`, `error` for various states
  - Tab colors: `primary` for active tab
  - Error colors: `error`, `onError`
- **Impact**: 🔥 **CRITICAL** - Downloads management interface

#### 10. Search Screen ❌
- **File**: `lib/presentation/pages/search/search_screen.dart`
- **Status**: ❌ **MASSIVE usage** - (~40+ instances)
- **Current Issues**:
  - Background colors: `darkBackground`, `darkCard`, `darkSurface`
  - Accent colors: `accentBlue`, `accentRed` for various states
  - Text colors: All dark text variants
  - Border colors: `borderDefault`
- **Impact**: 🔥 **CRITICAL** - Search functionality

#### 11. Favorites Screen ❌
- **File**: `lib/presentation/pages/favorites/favorites_screen.dart`
- **Status**: ❌ **MASSIVE usage** - (~50+ instances)
- **Current Issues**:
  - Background colors: `darkBackground`, `darkCard`, `darkSurface`
  - Action colors: `accentGreen`, `accentRed`, `accentBlue`
  - Text colors: All dark text variants extensively
  - Selection colors: Various accent colors
- **Impact**: 🔥 **CRITICAL** - Favorites management

#### 12. Offline Content Screen ❌
- **File**: `lib/presentation/pages/offline/offline_content_screen.dart`
- **Status**: ❌ **SIGNIFICANT usage** - (~15+ instances)
- **Current Issues**:
  - Background colors: `darkBackground`, `darkSurface`
  - Accent colors: `accentGreen`, `accentBlue`
  - Text colors: `darkTextPrimary`, `darkTextSecondary`
  - Border colors: `borderMuted`, `borderDefault`
- **Impact**: 🔥 **HIGH** - Offline content management

**ADDITIONAL WIDGETS NEEDING UPDATES:**

#### 13. Error Widget ❌
- **File**: `lib/presentation/widgets/error_widget.dart`
- **Status**: ❌ Minor hardcoded colors
- **Issues**: `Colors.orange`, `Colors.red` hardcoded values
- **Impact**: 🟡 **MEDIUM** - Error state display

#### 14. Platform Not Supported Dialog ❌
- **File**: `lib/presentation/widgets/platform_not_supported_dialog.dart`
- **Status**: ❌ Minor hardcoded colors
- **Issues**: `Colors.orange` hardcoded
- **Impact**: 🟡 **LOW** - Platform compatibility message

#### 15. Widget Examples ❌
- **File**: `lib/presentation/widgets/widget_examples.dart`
- **Status**: ❌ Minor hardcoded colors
- **Issues**: `Colors.grey[800]`, `Colors.white` hardcoded
- **Impact**: 🟡 **LOW** - Development examples only

### ⚠️ Medium Priority - Partial Theming (0/5 completed)
- [ ] **Search Screen** (0/3 tasks)
- [ ] **Downloads Screen** (0/2 tasks)
- [ ] **Splash Screen** (0/3 tasks)
- [ ] **Favorites Screen** (0/2 tasks)
- [ ] **Reader Screen** (0/2 tasks)

### 🔧 Low Priority - Minor Improvements (0/2 completed)
- [ ] **Main Screen** - Remove remaining hardcoded fontWeight (0/1 tasks)
- [ ] **Detail Screen** - Clean up remaining hardcoded values (0/1 tasks)

---

## 🎨 Expected Benefits

### User Experience
- **Consistent Visual Identity**: Unified color scheme and typography
- **Better Accessibility**: Proper contrast ratios and readable text sizes
- **Theme Switching Ready**: Prepared for light/dark theme switching
- **Professional Appearance**: Cohesive design language

### Developer Experience
- **Maintainability**: Centralized theme management
- **Scalability**: Easy to add new components with consistent styling
- **Debugging**: Easier to identify and fix styling issues
- **Team Collaboration**: Clear design system guidelines

### Performance
- **Reduced Bundle Size**: Eliminate duplicate color/style definitions
- **Better Caching**: Consistent theme objects can be cached efficiently
- **Faster Development**: Reusable theme components speed up development

---

## 📚 References

- **Color Constants**: `lib/core/constants/colors_const.dart`
- **Text Style Constants**: `lib/core/constants/text_style_const.dart`
- **Theme State**: `lib/presentation/cubits/theme/theme_state.dart`
- **Material Design 3**: [Material Design Guidelines](https://m3.material.io/)
- **Flutter Theming**: [Flutter Theme Documentation](https://docs.flutter.dev/cookbook/design/themes)

---

## 🚀 Getting Started

1. **Review Reference Implementation**: Study `settings_screen.dart` for the preferred Material 3 + TextStyleConst approach
2. **Start with High Priority**: Begin with `progressive_image_widget.dart` (completely unthemed)
3. **Create a Branch**: `git checkout -b theme-update/progressive-image-widget`  
4. **Follow the Pattern**: Use Material 3 approach like settings_screen.dart
5. **Test Thoroughly**: Ensure no visual regressions
6. **Create Pull Request**: Document changes and include before/after screenshots

### Quick Reference - Preferred Pattern from settings_screen.dart
```dart
// Text with theme integration
Text(
  'Title',
  style: TextStyleConst.headingSmall.copyWith(
    color: Theme.of(context).colorScheme.primary,
  ),
),

// Container with theme colors
Container(
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    border: Border.all(
      color: Theme.of(context).colorScheme.outline,
    ),
  ),
)
```

---

*Last Updated: August 30, 2025*
*Status: Planning Phase*
*Estimated Completion: 4 weeks*
