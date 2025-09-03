import 'package:flutter/material.dart';
import '../../presentation/cubits/settings/settings_cubit.dart';

/// Helper class for creating responsive grid delegates based on user settings
/// 
/// This class provides a centralized way to create grid delegates that respect
/// user preferences for column counts in different orientations.
class ResponsiveGridDelegate {
  /// Creates a grid delegate with column count based on orientation and user settings
  /// 
  /// [context] - BuildContext for accessing MediaQuery
  /// [settingsCubit] - SettingsCubit for accessing user column preferences
  /// [childAspectRatio] - Optional override for child aspect ratio (defaults to 0.7)
  /// [crossAxisSpacing] - Optional override for cross axis spacing (defaults to 8)
  /// [mainAxisSpacing] - Optional override for main axis spacing (defaults to 8)
  static SliverGridDelegate createGridDelegate(
    BuildContext context,
    SettingsCubit settingsCubit, {
    double childAspectRatio = 0.7,
    double crossAxisSpacing = 8.0,
    double mainAxisSpacing = 8.0,
  }) {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final columns = settingsCubit.getColumnsForOrientation(isPortrait);
    
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
    );
  }

  /// Creates a standard grid delegate for use with GridView.builder
  /// 
  /// [context] - BuildContext for accessing MediaQuery
  /// [settingsCubit] - SettingsCubit for accessing user column preferences
  /// [childAspectRatio] - Optional override for child aspect ratio (defaults to 0.7)
  /// [crossAxisSpacing] - Optional override for cross axis spacing (defaults to 8)
  /// [mainAxisSpacing] - Optional override for main axis spacing (defaults to 8)
  static SliverGridDelegateWithFixedCrossAxisCount createStandardGridDelegate(
    BuildContext context,
    SettingsCubit settingsCubit, {
    double childAspectRatio = 0.7,
    double crossAxisSpacing = 8.0,
    double mainAxisSpacing = 8.0,
  }) {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final columns = settingsCubit.getColumnsForOrientation(isPortrait);
    
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
    );
  }

  /// Get column count directly without creating delegate
  /// 
  /// [context] - BuildContext for accessing MediaQuery
  /// [settingsCubit] - SettingsCubit for accessing user column preferences
  static int getColumnCount(
    BuildContext context,
    SettingsCubit settingsCubit,
  ) {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    return settingsCubit.getColumnsForOrientation(isPortrait);
  }
}
