import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nhasixapp/core/routing/app_route.dart';

import '../../../widgets/widgets.dart';

/// Widget displayed when history is empty
class HistoryEmptyWidget extends StatelessWidget {
  const HistoryEmptyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No Reading History',
      message: 'Your reading history will appear here as you read content.',
      icon: Icons.history,
      onAction: () {
        // Navigate to main/browse screen
        context.go(AppRoute.main);
      },
      actionText: 'Start Reading',
      suggestions: const [
        'Browse popular content',
        'Search for something interesting',
        'Check out featured items',
      ],
    );
  }
}
