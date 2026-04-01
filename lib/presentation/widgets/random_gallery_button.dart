import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/routing/app_router.dart';
import 'package:nhasixapp/domain/repositories/content_repository.dart';
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
  final Logger _logger = Logger();

  Future<void> _handleRandomGallery() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final sourceId =
          context.read<SourceCubit>().state.activeSource?.id ?? 'nhentai';
      final repo = getIt<ContentRepository>();

      // Fetch random gallery(ies)
      final randomGalleries = await repo.getRandomGalleries(
        sourceId: sourceId,
        count: 1,
      );

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
          const SnackBar(content: Text('No random gallery found. Try again!')),
        );
      }
    } catch (e) {
      _logger.e('Failed to fetch random gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: 'Roll the dice for a random gallery!',
      child: IconButton(
        onPressed: _isLoading ? null : _handleRandomGallery,
        icon: AnimatedDiceWidget(
          isSpinning: _isLoading,
          duration: const Duration(milliseconds: 600),
          onSpinComplete: () {
            // Animation complete (gallery fetch happens in parallel)
          },
        ),
        tooltip: 'Random Gallery',
        splashRadius: 24,
        disabledColor: colorScheme.onSurface.withValues(alpha: 0.3),
      ),
    );
  }
}
