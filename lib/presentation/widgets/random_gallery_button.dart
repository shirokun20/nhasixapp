import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/routing/app_router.dart';
import 'package:nhasixapp/domain/repositories/content_repository.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/presentation/cubits/source/source_cubit.dart';
import 'animated_dice_widget.dart';

/// Random Gallery Button — Rolls a dice to get random content
class RandomGalleryButton extends StatefulWidget {
  const RandomGalleryButton({super.key});

  @override
  State<RandomGalleryButton> createState() => _RandomGalleryButtonState();
}

class _RandomGalleryButtonState extends State<RandomGalleryButton> {
  bool _isLoading = false;
  bool _isDialogOpen = false;
  final Logger _logger = Logger();
  final ValueNotifier<bool> _foundState = ValueNotifier<bool>(false);

  Future<void> _showLoadingDialog() async {
    if (!mounted || _isDialogOpen) return;

    _isDialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        return PopScope(
          canPop: false,
          child: ValueListenableBuilder<bool>(
            valueListenable: _foundState,
            builder: (context, found, child) {
              return AlertDialog(
                contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                content: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedDiceWidget(
                      isSpinning: !found,
                      duration: const Duration(milliseconds: 600),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            found
                                ? l10n.randomGalleryFoundTitle
                                : l10n.randomGalleryLoadingTitle,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            found
                                ? l10n.randomGalleryFoundMessage
                                : l10n.randomGalleryLoadingMessage,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    _isDialogOpen = false;
  }

  void _closeLoadingDialog() {
    if (!_isDialogOpen || !mounted) return;
    _isDialogOpen = false;
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _handleRandomGallery() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    _foundState.value = false;
    unawaited(_showLoadingDialog());

    try {
      final sourceId =
          context.read<SourceCubit>().state.activeSource?.id ?? 'nhentai';
      final repo = getIt<ContentRepository>();

      // Fetch random gallery(ies)
      final randomGalleries = await repo.getRandomGalleries(
        sourceId: sourceId,
        count: 1,
      );

      if (!mounted) return;

      if (randomGalleries.isNotEmpty) {
        _foundState.value = true;
        await Future<void>.delayed(const Duration(seconds: 2));
      }

      _closeLoadingDialog();

      if (randomGalleries.isNotEmpty && mounted) {
        final randomGallery = randomGalleries.first;

        // Navigate to detail screen
        await AppRouter.goToContentDetail(
          context,
          randomGallery.id,
          sourceId: sourceId,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.randomGalleryNoResult)),
        );
      }
    } catch (e) {
      _closeLoadingDialog();
      _logger.e('Failed to fetch random gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.randomGalleryError)),
        );
      }
    } finally {
      _closeLoadingDialog();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Tooltip(
      message: l10n.randomGallery,
      child: IconButton(
        onPressed: _isLoading ? null : _handleRandomGallery,
        icon: const AnimatedDiceWidget(isSpinning: false),
        tooltip: l10n.randomGallery,
        splashRadius: 24,
        disabledColor: colorScheme.onSurface.withValues(alpha: 0.3),
      ),
    );
  }

  @override
  void dispose() {
    _foundState.dispose();
    super.dispose();
  }
}
