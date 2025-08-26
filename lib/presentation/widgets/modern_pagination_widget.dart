import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nhasixapp/core/constants/colors_const.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';

/// Modern simplified pagination widget with tap-to-jump functionality
/// Keeps essential functionality but with cleaner, smaller design
class ModernPaginationWidget extends StatefulWidget {
  const ModernPaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
    required this.onNextPage,
    required this.onPreviousPage,
    required this.onGoToPage,
  });

  final int currentPage;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;
  final VoidCallback onNextPage;
  final VoidCallback onPreviousPage;
  final Function(int) onGoToPage;

  @override
  State<ModernPaginationWidget> createState() => _ModernPaginationWidgetState();
}

class _ModernPaginationWidgetState extends State<ModernPaginationWidget> {
  final TextEditingController _pageController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showPageJumpDialog() {
    _pageController.text = widget.currentPage.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorsConst.darkCard,
        title: Text(
          'Jump to Page',
          style: TextStyleConst.headingSmall.copyWith(
            color: ColorsConst.darkTextPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter page number (1 - ${widget.totalPages})',
              style: TextStyleConst.bodyMedium.copyWith(
                color: ColorsConst.darkTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pageController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              style: TextStyleConst.bodyLarge.copyWith(
                color: ColorsConst.darkTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Page number',
                hintStyle: TextStyleConst.bodyMedium.copyWith(
                  color: ColorsConst.darkTextTertiary,
                ),
                filled: true,
                fillColor: ColorsConst.darkBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: ColorsConst.borderDefault),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: ColorsConst.borderDefault),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: ColorsConst.accentBlue, width: 2),
                ),
              ),
              autofocus: true,
              onSubmitted: (value) {
                _goToPage();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyleConst.bodyMedium.copyWith(
                color: ColorsConst.darkTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _goToPage();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsConst.accentBlue,
              foregroundColor: ColorsConst.darkBackground,
            ),
            child: Text(
              'Go',
              style: TextStyleConst.bodyMedium.copyWith(
                color: ColorsConst.darkBackground,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goToPage() {
    final pageText = _pageController.text.trim();
    if (pageText.isEmpty) return;

    final page = int.tryParse(pageText);
    if (page == null || page < 1 || page > widget.totalPages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid page number between 1 and ${widget.totalPages}',
            style: TextStyleConst.bodyMedium.copyWith(
              color: ColorsConst.darkBackground,
            ),
          ),
          backgroundColor: ColorsConst.accentRed,
        ),
      );
      return;
    }

    widget.onGoToPage(page);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: ColorsConst.darkSurface,
        border: Border(
          top: BorderSide(
            color: ColorsConst.borderDefault,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          IconButton(
            onPressed: widget.hasPrevious ? widget.onPreviousPage : null,
            icon: const Icon(Icons.chevron_left),
            color: widget.hasPrevious
                ? ColorsConst.darkTextPrimary
                : ColorsConst.darkTextTertiary,
            tooltip: 'Previous page',
          ),
          
          // Page info with tap-to-jump functionality
          GestureDetector(
            onTap: _showPageJumpDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: ColorsConst.darkCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ColorsConst.borderDefault),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.currentPage} / ${widget.totalPages}',
                    style: TextStyleConst.bodyLarge.copyWith(
                      color: ColorsConst.darkTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to jump',
                    style: TextStyleConst.overline.copyWith(
                      color: ColorsConst.darkTextTertiary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Next button
          IconButton(
            onPressed: widget.hasNext ? widget.onNextPage : null,
            icon: const Icon(Icons.chevron_right),
            color: widget.hasNext
                ? ColorsConst.darkTextPrimary
                : ColorsConst.darkTextTertiary,
            tooltip: 'Next page',
          ),
        ],
      ),
    );
  }
}
