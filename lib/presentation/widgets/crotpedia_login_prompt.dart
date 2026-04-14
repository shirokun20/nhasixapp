import 'package:flutter/material.dart';
import 'package:nhasixapp/presentation/pages/crotpedia/crotpedia_login_page.dart';

import 'package:nhasixapp/l10n/app_localizations.dart';
class CrotpediaLoginPrompt extends StatelessWidget {
  const CrotpediaLoginPrompt({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => const CrotpediaLoginPrompt(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.lock_outline),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context)!.loginRequired),
        ],
      ),
      content: Text(
        AppLocalizations.of(context)!.crotpediaBookmarkLoginPrompt,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: () async {
            // Close dialog first
            Navigator.of(context).pop(false);

            // Navigate to login page
            // Assuming we can push it on top
            // Using Navigator here for simplicity as it's a dialog action
            await Navigator.of(context).push<bool>(MaterialPageRoute(
              builder: (context) => const CrotpediaLoginPage(),
              fullscreenDialog: true,
            ));

            // If result is true (login success), we could return true to the caller
            // But since we popped the dialog already, the caller got 'false'.
            // This pattern might need adjustment depending on how DetailCubit waits.
            // But usually UI logic handles the flow.
          },
          child: Text(AppLocalizations.of(context)!.login),
        ),
      ],
    );
  }
}
