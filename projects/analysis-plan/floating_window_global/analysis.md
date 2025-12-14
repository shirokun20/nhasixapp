# Analysis: Global Floating Window Black Screen

## Problem
The "Blank Screen" issue persists across multiple screens (Downloads, Details, Reading, Offline, Settings, History) in floating window mode on Xiaomi devices.

## Scope
Affected Screens:
1.  `DownloadsScreen`
2.  `ContentDetailScreen`
3.  `ReadingScreen` (Viewer)
4.  `OfflineContentScreen`
5.  `SettingsScreen`
6.  `HistoryScreen`

## Hypothesis
1.  **Grid Screens (Downloads, Offline, History)**: If they use `ResponsiveGridDelegate`, they might already be partially fixed by my previous change. If they use hardcoded delegates, they need the same fix. They also likely need `SliverSafeArea`.
2.  **List Screens (Settings)**: `ListView` usually handles small width well, but if wrapped in `ConstrainedBox` or using specific headers/footers with fixed widths > screen width, it might break.
3.  **Complex Screens (Details, Reading)**:
    -   **Details**: Often has a Row of image + text. If width < image width + text width, `Row` overflows (yellow/black tape) or crashes layout. Needs `Wrap` or `LayoutBuilder`.
    -   **Reading**: `ExtendedImage` might fail if `constraints.maxWidth` is near 0.

## Investigation Plan
1.  **Grep/Check imports** of `ResponsiveGridDelegate` in all target files.
2.  **Review Layouts**:
    -   **Settings**: Check for fixed-width widgets.
    -   **Details**: Check for `Row` that should be responsive.
    -   **Reading**: Check `ExtendedImageGesturePageView` constraints.
3.  **SafeArea**: Verify `SliverSafeArea` or `SafeArea` presence in all `Scaffold` bodies.

## Action Items
-   Create a shared `SafeScaffoldBody` or similar wrapper? Or just apply fixes individually.
-   Ensure all Grids use the patched `ResponsiveGridDelegate`.
