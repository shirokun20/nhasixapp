# Plan: Fix Floating Window Blank Screen

## Objective
Prevent the "Blank Screen" issue in floating/pop-up windows on Xiaomi devices by implementing responsive layout safeguards. The goal is to ensure the app renders usable content even in small or unusual window sizes.

## Design Decisions
1.  **Adaptive Grid Columns**: Modify `ResponsiveGridDelegate` to stop blindly obeying user preferences (e.g., 5 columns) when the screen width is insufficient.
    -   Introduce a `minItemWidth` constant (e.g., 120dp or 140dp).
    -   Calculate `maxPossibleColumns = availableWidth / minItemWidth`.
    -   `finalColumns = min(userPreferredColumns, maxPossibleColumns)`.
    -   Ensure `finalColumns` is at least 1.

2.  **SafeArea Integration**:
    -   Ensure `MainScreenScrollable` content is wrapped in `SafeArea` (or at least the Sliver padding respects it) to avoid drawing under floating window decorations.

3.  **Defensive LayoutBuilder** (Optional but recommended):
    -   In `MainScreenScrollable`, if `constraints.maxWidth` is extremely small (< 100dp), render a "Window too small" icon or minimal list instead of a broken grid.

## Detailed Steps
1.  **Modify `lib/core/utils/responsive_grid_delegate.dart`**:
    -   Update `createGridDelegate` and `createStandardGridDelegate`.
    -   Implement the logic:
        ```dart
        final double screenWidth = MediaQuery.of(context).size.width;
        final int userColumns = settingsCubit.getColumnsForOrientation(isPortrait);
        
        // Safety check for small screens
        const double minItemWidth = 140.0; // Moderate size for readability
        final int maxColumnsByWidth = (screenWidth / minItemWidth).floor();
        final int effectiveColumns = maxColumnsByWidth > 0 
            ? userColumns.clamp(1, maxColumnsByWidth) 
            : 1;
        ```

2.  **Verify**:
    -   Since I cannot run on the specific device, I will rely on this logic being "Correct by Construction" for responsive design.
    -   This prevents the "0 width item" or "negative size" scenario which causes layout cancellations.

## Impact
-   **Positive**: Better experience on Foldables, Tablets (multi-window), and Desktop (resizable windows).
-   **Negative**: User might see fewer columns than requested if they aggressively shrink the window, which is intended behavior.

## Verification
-   Will use `flutter test` if possible, or manual verification by reducing window size on Desktop/Emulator if available (User is on Mac, might be able to resize window if running macOS target, but target is likely Android).
