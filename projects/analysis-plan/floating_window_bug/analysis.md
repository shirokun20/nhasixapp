# Analysis: Floating Window Blank Screen Bug

## Problem Description
The application displays a blank screen when run in floating or pop-up windows on Xiaomi devices.
- **Symptoms**: Body is blank. Drawer (Scaffold.drawer) is functional (meaning the widget tree is alive and interactive).
- **Working**: Split-screen mode works. Normal mode works.
- **Environment**: Xiaomi devices (MIUI/HyperOS), Floating/Pop-up window mode.

## Codebase Analysis
### 1. Main Navigation & Layout
- **File**: `lib/presentation/pages/main/main_screen_scrollable.dart`
- **Structure**:
  - Uses `AppScaffoldWithOffline` (custom Scaffold wrapper).
  - Body is a `Column` containing `OfflineBanner` and an `Expanded` content area.
  - Content area is a `CustomScrollView` with a `SliverGrid`.
  - Grid delegate is `ResponsiveGridDelegate`.

### 2. Layout Logic
- **`ResponsiveGridDelegate`** (`lib/core/utils/responsive_grid_delegate.dart`):
  - Uses `MediaQuery.of(context).orientation` to check portrait/landscape.
  - Fetches column count from `SettingsCubit` (`getColumnsForOrientation`).
  - Uses `SliverGridDelegateWithFixedCrossAxisCount`.

### 3. Hypothesis
The "Blank Screen" is likely a layout collapse or rendering failure due to:
1.  **Extreme Constraints**: Floating windows can be very small (e.g., 300px wide). `SettingsCubit` might return 3 columns (default for landscape) if the aspect ratio is landscape-ish, or 2 for portrait.
    - If width is 300px, 3 columns -> ~90px items. This *should* render, but might be borderline if padding is large.
    - If `SliverPadding` (16px) + Spacing (16px) > Width, items become negative or 0 size.
2.  **MediaQuery Inconsistency**: In multi-window mode, `MediaQuery.size` might report 0 or invalid values during initialization frames, causing `SliverGrid` to fail silently or render nothing.
3.  **Missing SafeArea**: `MainScreenScrollable` body extends to edges. If the floating window has large insets (decoration), content might be obscured, although "Blank" implies empty, not just covered edges.
4.  **Device-Specific Rendering**: Xiaomi floating windows might handle `SurfaceView` or `TextureView` differently, but Flutter draws to a single Surface. Since Drawer works, the Surface is valid.

## Conclusions
The code lacks defensive handling for **small window sizes**. It relies on `MediaQuery.orientation` (which is just Aspect Ratio check) to determine layout headers (Portrait vs Landscape columns).
- If a floating window is "Landscape" (Width > Height) but effectively tiny (e.g. 400x300), it might try to squeeze 3-5 columns (user setting for landscape) into 400px.

## Plan Direction
1.  **Robust Grid Layout**: Modify `ResponsiveGridDelegate` or `MainScreenScrollable` to enforce a minimum item width (e.g., 150px). If the screen width can't fit the requested columns, reduce column count dynamically to 1 or 2.
2.  **Defensive Rendering**: Wrap the body in `LayoutBuilder` to inspect actual constraints. If constraints are too small, show a "Window too small" placeholder or switch to a simplified List layout.
3.  **SafeArea**: Ensure the list respects `SafeArea` (though `SliverPadding` usually handles this if configured).
