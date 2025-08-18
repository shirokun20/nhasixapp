import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/constants/colors_const.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import '../../../domain/entities/user_preferences.dart';
import '../../cubits/settings/settings_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsConst.background,
      appBar: AppBar(
        backgroundColor: ColorsConst.surface,
        title: Text('Settings', style: TextStyleConst.headingMedium),
        iconTheme: const IconThemeData(color: ColorsConst.darkTextPrimary),
        elevation: 0,
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoaded) {
            final prefs = state.preferences;
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text('Tampilan', style: TextStyleConst.headingSmall),
                ),
                ListTile(
                  tileColor: ColorsConst.surface,
                  title: Text('Theme', style: TextStyleConst.bodyLarge),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    margin: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: ColorsConst.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ColorsConst.borderDefault, width: 1.2),
                    ),
                    child: DropdownButton<String>(
                      value: prefs.theme,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, color: ColorsConst.borderDefault),
                      style: TextStyleConst.bodyLarge.copyWith(color: ColorsConst.darkTextPrimary),
                      dropdownColor: ColorsConst.surface,
                      borderRadius: BorderRadius.circular(8),
                      items: ThemeOption.all.map((theme) {
                        return DropdownMenuItem<String>(
                          value: theme,
                          child: Text(
                            ThemeOption.getDisplayName(theme),
                            style: TextStyleConst.bodyLarge.copyWith(color: ColorsConst.darkTextPrimary),
                          ),
                        );
                      }).toList(),
                      onChanged: (theme) {
                        if (theme != null) {
                          context.read<SettingsCubit>().updateTheme(theme);
                        }
                      },
                    ),
                  ),
                ),
                ListTile(
                  tileColor: ColorsConst.surface,
                  title: Text('Language', style: TextStyleConst.bodyLarge),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    margin: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: ColorsConst.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ColorsConst.borderDefault, width: 1.2),
                    ),
                    child: DropdownButton<String>(
                      value: prefs.defaultLanguage,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, color: ColorsConst.borderDefault),
                      style: TextStyleConst.bodyLarge.copyWith(color: ColorsConst.darkTextPrimary),
                      dropdownColor: ColorsConst.surface,
                      borderRadius: BorderRadius.circular(8),
                      items: [
                        DropdownMenuItem(
                          value: 'english',
                          child: Text('English', style: TextStyleConst.bodyLarge),
                        ),
                        DropdownMenuItem(
                          value: 'japanese',
                          child: Text('Japanese', style: TextStyleConst.bodyLarge),
                        ),
                      ],
                      onChanged: (lang) {
                        if (lang != null) {
                          context.read<SettingsCubit>().updateDefaultLanguage(lang);
                        }
                      },
                    ),
                  ),
                ),
                ListTile(
                  tileColor: ColorsConst.surface,
                  title: Text('Image Quality', style: TextStyleConst.bodyLarge),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    margin: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: ColorsConst.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ColorsConst.borderDefault, width: 1.2),
                    ),
                    child: DropdownButton<String>(
                      value: prefs.imageQuality,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, color: ColorsConst.borderDefault),
                      style: TextStyleConst.bodyLarge.copyWith(color: ColorsConst.darkTextPrimary),
                      dropdownColor: ColorsConst.surface,
                      borderRadius: BorderRadius.circular(8),
                      items: ImageQuality.all.map((q) {
                        return DropdownMenuItem<String>(
                          value: q,
                          child: Text(
                            ImageQuality.getDisplayName(q),
                            style: TextStyleConst.bodyLarge.copyWith(color: ColorsConst.darkTextPrimary),
                          ),
                        );
                      }).toList(),
                      onChanged: (q) {
                        if (q != null) {
                          context.read<SettingsCubit>().updateImageQuality(q);
                        }
                      },
                    ),
                  ),
                ),
                ListTile(
                  tileColor: ColorsConst.surface,
                  title: Text('Grid Columns (Portrait)', style: TextStyleConst.bodyLarge),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    margin: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: ColorsConst.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ColorsConst.borderDefault, width: 1.2),
                    ),
                    child: DropdownButton<int>(
                      value: prefs.columnsPortrait,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, color: ColorsConst.borderDefault),
                      style: TextStyleConst.bodyLarge.copyWith(color: ColorsConst.darkTextPrimary),
                      dropdownColor: ColorsConst.surface,
                      borderRadius: BorderRadius.circular(8),
                      items: [2, 3, 4].map((count) {
                        return DropdownMenuItem<int>(
                          value: count,
                          child: Text('$count', style: TextStyleConst.bodyLarge.copyWith(color: ColorsConst.darkTextPrimary)),
                        );
                      }).toList(),
                      onChanged: (count) {
                        if (count != null) {
                          context.read<SettingsCubit>().updateColumnsPortrait(count);
                        }
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text('Pembaca', style: TextStyleConst.headingSmall),
                ),
                SwitchListTile(
                  tileColor: ColorsConst.surface,
                  activeColor: ColorsConst.accentBlue,
                  title: Text('Show System UI in Reader', style: TextStyleConst.bodyLarge),
                  value: prefs.showSystemUI,
                  onChanged: (val) {
                    context.read<SettingsCubit>().updateShowSystemUI(val);
                  },
                ),
                // Tambahkan pengaturan reader lain di sini
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text('Lainnya', style: TextStyleConst.headingSmall),
                ),
                // Contoh: Reset ke default
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh, color: ColorsConst.onError),
                    label: Text('Reset ke Default', style: TextStyleConst.buttonLarge.copyWith(color: ColorsConst.onError)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsConst.error,
                      foregroundColor: ColorsConst.onError,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: ColorsConst.surface,
                          title: Text('Reset Settings', style: TextStyleConst.headingSmall),
                          content: Text('Yakin ingin mengembalikan semua pengaturan ke default?', style: TextStyleConst.bodyLarge),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text('Batal', style: TextStyleConst.bodyLarge.copyWith(color: ColorsConst.borderDefault)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorsConst.error,
                                foregroundColor: ColorsConst.onError,
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text('Reset', style: TextStyleConst.bodyLarge.copyWith(color: ColorsConst.onError)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        context.read<SettingsCubit>().resetToDefaults();
                      }
                    },
                  ),
                ),
              ],
            );
          } else if (state is SettingsError) {
            return Center(child: Text(state.userFriendlyMessage));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
