import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import '../../core/constants/text_style_const.dart';

class PlatformNotSupportedDialog extends StatelessWidget {
  const PlatformNotSupportedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AlertDialog(
      backgroundColor: colorScheme.surface,
      icon: Icon(
        Icons.warning_amber_rounded,
        color: colorScheme.tertiary,
        size: 48,
      ),
      title: Text(
        'Platform Not Supported',
        style: TextStyleConst.headlineSmall.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'NhasixApp is designed exclusively for Android devices.',
            textAlign: TextAlign.center,
            style: TextStyleConst.bodyMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Please install and run this app on an Android device.',
            textAlign: TextAlign.center,
            style: TextStyleConst.titleMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
          ),
          child: Text(
            'OK',
            style: TextStyleConst.labelLarge.copyWith(
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  /// Show platform not supported dialog
  static void show(BuildContext context) {
    if (kIsWeb || (!kIsWeb && !Platform.isAndroid)) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const PlatformNotSupportedDialog(),
      );
    }
  }
}
