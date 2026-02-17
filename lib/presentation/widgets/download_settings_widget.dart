import 'package:flutter/material.dart';

import '../../core/constants/text_style_const.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/storage_settings.dart';
import '../blocs/download/download_bloc.dart';

/// Widget for configuring download settings
class DownloadSettingsWidget extends StatefulWidget {
  const DownloadSettingsWidget({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  final DownloadSettings settings;
  final Function(DownloadSettings) onSettingsChanged;

  @override
  State<DownloadSettingsWidget> createState() => _DownloadSettingsWidgetState();
}

class _DownloadSettingsWidgetState extends State<DownloadSettingsWidget> {
  late DownloadSettings _settings;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      constraints: const BoxConstraints(maxHeight: 600),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Text(
                  AppLocalizations.of(context)?.downloadSettingsTitle ??
                      'Download Settings',
                  style: TextStyleConst.headlineSmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // Settings form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Concurrent downloads
                    _buildSectionTitle(
                        AppLocalizations.of(context)?.performanceSection ??
                            'Performance'),
                    _buildConcurrentDownloadsSlider(),
                    const SizedBox(height: 16),

                    // Image quality
                    _buildImageQualityDropdown(),
                    const SizedBox(height: 24),

                    // Auto retry settings
                    _buildSectionTitle(
                        AppLocalizations.of(context)?.autoRetrySection ??
                            'Auto Retry'),
                    _buildAutoRetrySwitch(),
                    if (_settings.autoRetry) ...[
                      const SizedBox(height: 8),
                      _buildRetryAttemptsSlider(),
                    ],
                    const SizedBox(height: 24),

                    // Network settings
                    _buildSectionTitle(
                        AppLocalizations.of(context)?.networkSection ??
                            'Network'),
                    _buildWifiOnlySwitch(),
                    const SizedBox(height: 16),
                    _buildTimeoutSlider(),
                    const SizedBox(height: 24),

                    // Notifications
                    _buildSectionTitle(
                        AppLocalizations.of(context)?.notificationsSection ??
                            'Notifications'),
                    _buildNotificationsSwitch(),
                    const SizedBox(height: 24),

                    // Storage
                    _buildSectionTitle(
                        AppLocalizations.of(context)?.storageSection ??
                            'Storage Location'),
                    _buildStorageSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.cancel ?? 'Cancel',
                      style: TextStyleConst.labelLarge,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.save ?? 'Save',
                      style: TextStyleConst.labelLarge.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyleConst.titleMedium.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildConcurrentDownloadsSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context)?.maxConcurrentDownloads ??
                  'Max Concurrent Downloads',
              style: TextStyleConst.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              '${_settings.maxConcurrentDownloads}',
              style: TextStyleConst.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _settings.maxConcurrentDownloads.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveColor:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(
                maxConcurrentDownloads: value.toInt(),
              );
            });
          },
        ),
        Text(
          AppLocalizations.of(context)?.concurrentDownloadsWarning ??
              'Higher values may consume more bandwidth and device resources',
          style: TextStyleConst.bodySmall.copyWith(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildImageQualityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)?.imageQualityLabel ?? 'Image Quality',
          style: TextStyleConst.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _settings.imageQuality,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          dropdownColor: Theme.of(context).colorScheme.surface,
          style: TextStyleConst.bodyMedium
              .copyWith(color: Theme.of(context).colorScheme.onSurface),
          items: [
            DropdownMenuItem(
                value: 'low',
                child: Text(AppLocalizations.of(context)!.lowQuality)),
            DropdownMenuItem(
                value: 'medium',
                child: Text(AppLocalizations.of(context)!.mediumQuality)),
            DropdownMenuItem(
                value: 'high',
                child: Text(AppLocalizations.of(context)!.highQuality)),
            DropdownMenuItem(
                value: 'original',
                child: Text(AppLocalizations.of(context)!.originalQuality)),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _settings = _settings.copyWith(imageQuality: value);
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildAutoRetrySwitch() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)?.autoRetryFailedDownloads ??
                    'Auto Retry Failed Downloads',
                style: TextStyleConst.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                AppLocalizations.of(context)?.autoRetryDescription ??
                    'Automatically retry failed downloads',
                style: TextStyleConst.bodySmall.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: _settings.autoRetry,
          activeThumbColor: Theme.of(context).colorScheme.primary,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(autoRetry: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildRetryAttemptsSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context)?.maxRetryAttempts ??
                  'Max Retry Attempts',
              style: TextStyleConst.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              '${_settings.retryAttempts}',
              style: TextStyleConst.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _settings.retryAttempts.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveColor:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(retryAttempts: value.toInt());
            });
          },
        ),
      ],
    );
  }

  Widget _buildWifiOnlySwitch() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)?.wifiOnlyLabel ?? 'WiFi Only',
                style: TextStyleConst.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                AppLocalizations.of(context)?.wifiOnlyDescription ??
                    'Only download when connected to WiFi',
                style: TextStyleConst.bodySmall.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: _settings.wifiOnly,
          activeThumbColor: Theme.of(context).colorScheme.primary,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(wifiOnly: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildTimeoutSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context)?.downloadTimeoutLabel ??
                  'Download Timeout',
              style: TextStyleConst.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              '${_settings.timeoutDuration.inMinutes} ${AppLocalizations.of(context)?.minutesUnit ?? 'min'}',
              style: TextStyleConst.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _settings.timeoutDuration.inMinutes.toDouble(),
          min: 1,
          max: 30,
          divisions: 29,
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveColor:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(
                timeoutDuration: Duration(minutes: value.toInt()),
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildNotificationsSwitch() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)?.enableNotificationsLabel ??
                    'Enable Notifications',
                style: TextStyleConst.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                AppLocalizations.of(context)?.enableNotificationsDescription ??
                    'Show notifications for download progress',
                style: TextStyleConst.bodySmall.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: _settings.enableNotifications,
          activeThumbColor: Theme.of(context).colorScheme.primary,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(enableNotifications: value);
            });
          },
        ),
      ],
    );
  }

  void _saveSettings() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSettingsChanged(_settings);
      Navigator.of(context).pop();
    }
  }

  Widget _buildStorageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)?.storageSection ?? 'Storage Location',
          style: TextStyleConst.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickCustomStorage,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.folder_open,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    (_settings.customStorageRoot != null &&
                            _settings.customStorageRoot!.isNotEmpty)
                        ? _settings.customStorageRoot!
                        : (AppLocalizations.of(context)?.defaultStorage ??
                            'Default (Internal)'),
                    style: TextStyleConst.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.edit,
                  size: 16,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppLocalizations.of(context)?.storageDescription ??
              'Select a custom folder for downloads',
          style: TextStyleConst.bodySmall.copyWith(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Future<void> _pickCustomStorage() async {
    final path = await StorageSettings.pickAndSaveCustomRoot(context);
    if (path != null) {
      // Reload the ACTUAL saved path from SharedPreferences to ensure consistency
      final savedPath = await StorageSettings.getCustomRootPath();
      if (mounted) {
        setState(() {
          _settings = _settings.copyWith(customStorageRoot: savedPath);
        });

        // 🚀 AUTO-APPLY: Immediately notify parent to update DownloadBloc
        // This ensures custom storage is active right away without requiring "Save" button click
        widget.onSettingsChanged(_settings);
      }
    }
  }
}
