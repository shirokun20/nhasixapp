# Execution: Fix Floating Window Globally

## Objective
Fix the "Blank Screen" issue in floating windows across all app screens.

## Tasks
1.  **Enhance `AppScaffoldWithOffline`**:
    -   File: `lib/presentation/widgets/app_scaffold_with_offline.dart`
    -   Action: Wrap the body content (inside `Expanded`) with a `LayoutBuilder`. If constraints are too small (e.g., width < 50 or height < 50), return a `SizedBox` or "Window too small" placeholder to prevent layout crashes.
    -   Action: Add `SafeArea` (bottom only?) or ensure it's safe. *Correction*: `SafeArea` usually helps, but `LayoutBuilder` is the critical crash preventer.

2.  **Fix `HistoryScreen`**:
    -   File: `lib/presentation/pages/history/history_screen.dart`
    -   Action: Wrap `Scaffold` body in `LayoutBuilder` + `SafeArea`.

3.  **Fix `ReaderScreen`**:
    -   File: `lib/presentation/pages/reader/reader_screen.dart`
    -   Action: Wrap `Scaffold` body in `LayoutBuilder`.

4.  **Fix `SettingsScreen`**:
    -   File: `lib/presentation/pages/settings/settings_screen.dart`
    -   Action: Apply adaptive column logic to the "Grid Preview" section (lines 294-330) using `LayoutBuilder` or just the `ResponsiveGridDelegate` logic manually.

5.  **Verify**:
    -   Compile and Analyze.

## Progress
- [ ] Initialize
