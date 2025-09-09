import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:logger/logger.dart';

import '../presentation/cubits/settings/settings_cubit.dart';
import '../presentation/cubits/theme/theme_cubit.dart';

/// Debug utility for theme debugging
class ThemeDebugUtility {
  static final Logger _logger = Logger();

  /// Log current theme state
  static void logCurrentTheme(BuildContext context) {
    try {
      final themeCubit = context.read<ThemeCubit>();
      final settingsCubit = context.read<SettingsCubit>();
      
      final themeState = themeCubit.state;
      final settingsState = settingsCubit.state;
      
      _logger.i('=== THEME DEBUG INFO ===');
      _logger.i('ThemeCubit.currentTheme: ${themeState.currentTheme}');
      _logger.i('ThemeCubit.themeMode: ${themeState.themeMode}');
      _logger.i('ThemeCubit.lastUpdated: ${themeState.lastUpdated}');
      
      if (settingsState is SettingsLoaded) {
        _logger.i('Settings.theme: ${settingsState.preferences.theme}');
        _logger.i('Settings.lastUpdated: ${settingsState.lastUpdated}');
      } else {
        _logger.w('Settings state: ${settingsState.runtimeType}');
      }
      
      // Log MaterialApp theme info
      final themeData = Theme.of(context);
      _logger.i('MaterialApp.brightness: ${themeData.brightness}');
      _logger.i('MaterialApp.scaffoldBackgroundColor: ${themeData.scaffoldBackgroundColor}');
      _logger.i('========================');
    } catch (e) {
      _logger.e('Error logging theme debug info: $e');
    }
  }

  /// Test theme change
  static Future<void> testThemeChange(BuildContext context, String newTheme) async {
    try {
      _logger.i('Testing theme change to: $newTheme');

      final settingsCubit = context.read<SettingsCubit>();
      await settingsCubit.updateTheme(newTheme);

      // Wait a bit for state updates
      await Future.delayed(const Duration(milliseconds: 100));

      // Check if context is still valid before logging
      if (context.mounted) {
        logCurrentTheme(context);
      }
    } catch (e) {
      _logger.e('Error testing theme change: $e');
    }
  }

  /// Debug widget to display current theme info
  static Widget debugThemeWidget(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settingsState) {
            return Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppLocalizations.of(context)!.debugThemeInfo, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('ThemeCubit.currentTheme: ${themeState.currentTheme}'),
                  Text('ThemeCubit.themeMode: ${themeState.themeMode}'),
                  if (settingsState is SettingsLoaded)
                    Text('Settings.theme: ${settingsState.preferences.theme}')
                  else
                    Text('Settings state: ${settingsState.runtimeType}'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => testThemeChange(context, 'light'),
                        child: Text(AppLocalizations.of(context)!.lightTheme),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => testThemeChange(context, 'dark'),
                        child: Text(AppLocalizations.of(context)!.darkTheme),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => testThemeChange(context, 'amoled'),
                        child: Text(AppLocalizations.of(context)!.amoledTheme),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
