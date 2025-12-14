# Execution: Tablet & DeX Optimization

## Objective
Enable a responsive "Dashboard" layout for large screens (Tablet/DeX/Desktop), transforming the existing Drawer-based navigation into a persistent Sidebar.

## Tasks
1.  **Extract Drawer Content**:
    -   File: `lib/presentation/widgets/app_drawer_content.dart` (NEW)
    -   Action: Move the `ListView` logic from `AppMainDrawerWidget` here.
    -   Action: Use `context.go` for navigation to prevent stack accumulation.
    -   Action: Handle `onTap` logic: if `isDrawerOpen` (passed in or detected), call `Navigator.pop`. If persistent sidebar, do not pop.

2.  **Update `AppMainDrawerWidget`**:
    -   File: `lib/presentation/widgets/app_main_drawer_widget.dart`
    -   Action: Simplify it to just return `Drawer(child: AppDrawerContent(isDrawer: true))`.

3.  **Modify `AppScaffoldWithOffline`**:
    -   File: `lib/presentation/widgets/app_scaffold_with_offline.dart`
    -   Action: Import `AppDrawerContent`.
    -   Action: Use `LayoutBuilder` (already added!) to check width.
    -   Action: If `maxWidth > 900`:
        -   Render `Row(children: [SizedBox(width: 280, child: AppDrawerContent(isDrawer: false)), Expanded(child: Scaffold(...))])`.
        -   Suppress `AppBar` drawer icon in the nested Scaffold (`automaticallyImplyLeading: false`).
    -   Action: Ensure `SafeArea` logic from previous fix keeps working.

## Progress
- [ ] Create `AppDrawerContent`
- [ ] Update `AppMainDrawerWidget`
- [ ] Update `AppScaffoldWithOffline`
