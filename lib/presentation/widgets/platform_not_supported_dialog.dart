import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class PlatformNotSupportedDialog extends StatelessWidget {
  const PlatformNotSupportedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: Colors.orange,
        size: 48,
      ),
      title: const Text('Platform Not Supported'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'NhasixApp is designed exclusively for Android devices.',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            'Please install and run this app on an Android device.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
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
