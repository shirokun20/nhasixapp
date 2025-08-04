import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nhasixapp/core/constants/colors_const.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';

/// Advanced pagination widget with page navigation and progress indicator
class PaginationWidget extends StatefulWidget {
  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
    required this.onNextPage,
    required this.onPreviousPage,
    required this.onGoToPage,
    this.showProgressBar = true,
    this.showPercentage = true,
    this.showPageInput = false,
  });

  final int currentPage;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;
  final VoidCallback onNextPage;
  final VoidCallback onPreviousPage;
  final Function(int) onGoToPage;
  final bool showProgressBar;
  final bool showPercentage;
  final bool showPageInput;

  @override
  State<PaginationWidget> createState() => _PaginationWidgetState();
}

class _PaginationWidgetState extends State<PaginationWidget> {
  final TextEditingController _pageController = TextEditingController();
  // bool _showPageInput = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  double get progressPercentage {
    if (widget.totalPages <= 0) return 0.0;
    return widget.currentPage / widget.totalPages;
  }

  void _showPageInputDialog() {
    _pageController.text = widget.currentPage.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorsConst.thirdColor,
        title: Text(
          'Go to Page',
          style: TextStyleConst.styleBold(
            textColor: ColorsConst.primaryTextColor,
            size: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter page number (1 - ${widget.totalPages})',
              style: TextStyleConst.styleRegular(
                textColor: ColorsConst.primaryTextColor.withValues(alpha: 0.8),
                size: 14,
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
              style: TextStyleConst.styleRegular(
                textColor: ColorsConst.primaryTextColor,
                size: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Page number',
                hintStyle: TextStyleConst.styleRegular(
                  textColor:
                      ColorsConst.primaryTextColor.withValues(alpha: 0.5),
                  size: 16,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: ColorsConst.primaryTextColor.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: ColorsConst.redCustomColor,
                  ),
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
              style: TextStyleConst.styleRegular(
                textColor: ColorsConst.primaryTextColor.withValues(alpha: 0.7),
                size: 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _goToPage();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsConst.redCustomColor,
            ),
            child: Text(
              'Go',
              style: TextStyleConst.styleBold(
                textColor: Colors.white,
                size: 14,
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
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: ColorsConst.redCustomColor,
        ),
      );
      return;
    }

    widget.onGoToPage(page);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorsConst.thirdColor,
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main pagination row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Previous button
              IconButton(
                iconSize: 32,
                onPressed: widget.hasPrevious ? widget.onPreviousPage : null,
                icon: const Icon(Icons.chevron_left),
                color: widget.hasPrevious
                    ? ColorsConst.primaryTextColor
                    : ColorsConst.primaryTextColor.withValues(alpha: 0.3),
                tooltip: 'Previous page',
              ),

              const Spacer(),

              // Page info section
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: widget.showPageInput ? _showPageInputDialog : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Page text
                      Text(
                        'Page ${widget.currentPage} of ${widget.totalPages}',
                        style: TextStyleConst.styleBold(
                          textColor: ColorsConst.primaryTextColor,
                          size: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      if (widget.showProgressBar) ...[
                        const SizedBox(height: 6),
                        // Progress bar
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: ColorsConst.primaryTextColor
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progressPercentage,
                            child: Container(
                              decoration: BoxDecoration(
                                color: ColorsConst.redCustomColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],

                      if (widget.showPercentage) ...[
                        const SizedBox(height: 4),
                        // Progress percentage
                        Text(
                          '${(progressPercentage * 100).toStringAsFixed(1)}%',
                          style: TextStyleConst.styleRegular(
                            textColor: ColorsConst.primaryTextColor
                                .withValues(alpha: 0.7),
                            size: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      if (widget.showPageInput) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Tap to jump to page',
                          style: TextStyleConst.styleRegular(
                            textColor: ColorsConst.primaryTextColor
                                .withValues(alpha: 0.5),
                            size: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Next button
              IconButton(
                iconSize: 32,
                onPressed: widget.hasNext ? widget.onNextPage : null,
                icon: const Icon(Icons.chevron_right),
                color: widget.hasNext
                    ? ColorsConst.primaryTextColor
                    : ColorsConst.primaryTextColor.withValues(alpha: 0.3),
                tooltip: 'Next page',
              ),

              const Spacer(),
            ],
          ),

          // Additional info row (optional)
          if (widget.totalPages > 1000) ...[
            const SizedBox(height: 4),
            Text(
              'Total: ${widget.totalPages.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} pages',
              style: TextStyleConst.styleRegular(
                textColor: ColorsConst.primaryTextColor.withValues(alpha: 0.6),
                size: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Simple pagination widget for basic use cases
class SimplePaginationWidget extends StatelessWidget {
  const SimplePaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
    required this.onNextPage,
    required this.onPreviousPage,
  });

  final int currentPage;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;
  final VoidCallback onNextPage;
  final VoidCallback onPreviousPage;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorsConst.thirdColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          TextButton.icon(
            onPressed: hasPrevious ? onPreviousPage : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
            style: TextButton.styleFrom(
              foregroundColor: hasPrevious
                  ? ColorsConst.primaryTextColor
                  : ColorsConst.primaryTextColor.withValues(alpha: 0.3),
            ),
          ),

          // Page info
          Text(
            '$currentPage / $totalPages',
            style: TextStyleConst.styleBold(
              textColor: ColorsConst.primaryTextColor,
              size: 16,
            ),
          ),

          // Next button
          TextButton.icon(
            onPressed: hasNext ? onNextPage : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
            style: TextButton.styleFrom(
              foregroundColor: hasNext
                  ? ColorsConst.primaryTextColor
                  : ColorsConst.primaryTextColor.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
