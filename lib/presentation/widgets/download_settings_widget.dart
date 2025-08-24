import 'package:flutter/material.dart';

import '../../core/constants/colors_const.dart';
import '../../core/constants/text_style_const.dart';
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
                  'Download Settings',
                  style: TextStyleConst.headlineSmall.copyWith(
                    color: ColorsConst.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: ColorsConst.onSurface,
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
                    _buildSectionTitle('Performance'),
                    _buildConcurrentDownloadsSlider(),
                    const SizedBox(height: 16),

                    // Image quality
                    _buildImageQualityDropdown(),
                    const SizedBox(height: 24),

                    // Auto retry settings
                    _buildSectionTitle('Auto Retry'),
                    _buildAutoRetrySwitch(),
                    if (_settings.autoRetry) ...[
                      const SizedBox(height: 8),
                      _buildRetryAttemptsSlider(),
                    ],
                    const SizedBox(height: 24),

                    // Network settings
                    _buildSectionTitle('Network'),
                    _buildWifiOnlySwitch(),
                    const SizedBox(height: 16),
                    _buildTimeoutSlider(),
                    const SizedBox(height: 24),

                    // Notifications
                    _buildSectionTitle('Notifications'),
                    _buildNotificationsSwitch(),
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
                      foregroundColor: ColorsConst.onSurface.withValues(alpha: 0.7),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyleConst.labelLarge,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsConst.primary,
                      foregroundColor: ColorsConst.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Save',
                      style: TextStyleConst.labelLarge.copyWith(
                        color: ColorsConst.onPrimary,
                        fontWeight: FontWeight.w600,
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
          color: ColorsConst.onSurface,
          fontWeight: FontWeight.w600,
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
              'Max Concurrent Downloads',
              style: TextStyleConst.bodyMedium.copyWith(
                color: ColorsConst.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              '${_settings.maxConcurrentDownloads}',
              style: TextStyleConst.bodyMedium.copyWith(
                color: ColorsConst.primary,
                fontWeight: FontWeight.w600,
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
          activeColor: ColorsConst.primary,
          inactiveColor: ColorsConst.onSurface.withValues(alpha: 0.2),
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(
                maxConcurrentDownloads: value.toInt(),
              );
            });
          },
        ),
        Text(
          'Higher values may consume more bandwidth and device resources',
          style: TextStyleConst.bodySmall.copyWith(
            color: ColorsConst.onSurface.withValues(alpha: 0.6),
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
          'Image Quality',
          style: TextStyleConst.bodyMedium.copyWith(
            color: ColorsConst.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _settings.imageQuality,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: ColorsConst.onSurface.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: ColorsConst.onSurface.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: ColorsConst.primary),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          dropdownColor: ColorsConst.surface,
          style:
              TextStyleConst.bodyMedium.copyWith(color: ColorsConst.onSurface),
          items: const [
            DropdownMenuItem(value: 'low', child: Text('Low (Faster)')),
            DropdownMenuItem(value: 'medium', child: Text('Medium')),
            DropdownMenuItem(
                value: 'high', child: Text('High (Better Quality)')),
            DropdownMenuItem(
                value: 'original', child: Text('Original (Largest)')),
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
                'Auto Retry Failed Downloads',
                style: TextStyleConst.bodyMedium.copyWith(
                  color: ColorsConst.onSurface,
                ),
              ),
              Text(
                'Automatically retry failed downloads',
                style: TextStyleConst.bodySmall.copyWith(
                  color: ColorsConst.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: _settings.autoRetry,
          activeColor: ColorsConst.primary,
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
              'Max Retry Attempts',
              style: TextStyleConst.bodyMedium.copyWith(
                color: ColorsConst.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              '${_settings.retryAttempts}',
              style: TextStyleConst.bodyMedium.copyWith(
                color: ColorsConst.primary,
                fontWeight: FontWeight.w600,
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
          activeColor: ColorsConst.primary,
          inactiveColor: ColorsConst.onSurface.withValues(alpha: 0.2),
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
                'WiFi Only',
                style: TextStyleConst.bodyMedium.copyWith(
                  color: ColorsConst.onSurface,
                ),
              ),
              Text(
                'Only download when connected to WiFi',
                style: TextStyleConst.bodySmall.copyWith(
                  color: ColorsConst.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: _settings.wifiOnly,
          activeColor: ColorsConst.primary,
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
              'Download Timeout',
              style: TextStyleConst.bodyMedium.copyWith(
                color: ColorsConst.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              '${_settings.timeoutDuration.inMinutes} min',
              style: TextStyleConst.bodyMedium.copyWith(
                color: ColorsConst.primary,
                fontWeight: FontWeight.w600,
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
          activeColor: ColorsConst.primary,
          inactiveColor: ColorsConst.onSurface.withValues(alpha: 0.2),
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
                'Enable Notifications',
                style: TextStyleConst.bodyMedium.copyWith(
                  color: ColorsConst.onSurface,
                ),
              ),
              Text(
                'Show notifications for download progress',
                style: TextStyleConst.bodySmall.copyWith(
                  color: ColorsConst.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: _settings.enableNotifications,
          activeColor: ColorsConst.primary,
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
}
