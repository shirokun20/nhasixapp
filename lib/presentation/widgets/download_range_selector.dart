import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';

/// Widget for selecting download range (page X to page Y)
/// Allows users to download partial content instead of all pages
class DownloadRangeSelector extends StatefulWidget {
  final int totalPages;
  final Function(int startPage, int endPage) onRangeSelected;
  final String contentTitle;

  const DownloadRangeSelector({
    super.key,
    required this.totalPages,
    required this.onRangeSelected,
    required this.contentTitle,
  });

  @override
  State<DownloadRangeSelector> createState() => _DownloadRangeSelectorState();
}

class _DownloadRangeSelectorState extends State<DownloadRangeSelector> {
  late int startPage;
  late int endPage;
  late RangeValues _currentRangeValues;
  
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  @override
  void initState() {
    super.initState();
    startPage = 1;
    endPage = widget.totalPages;
    _currentRangeValues = RangeValues(1, widget.totalPages.toDouble());
    _updateControllers();
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  void _updateControllers() {
    _startController.text = startPage.toString();
    _endController.text = endPage.toString();
  }

  void _updateFromSlider() {
    setState(() {
      startPage = _currentRangeValues.start.round();
      endPage = _currentRangeValues.end.round();
      _updateControllers();
    });
  }

  void _updateFromTextFields() {
    final start = int.tryParse(_startController.text);
    final end = int.tryParse(_endController.text);
    
    if (start != null && end != null && 
        start >= 1 && end <= widget.totalPages && start <= end) {
      setState(() {
        startPage = start;
        endPage = end;
        _currentRangeValues = RangeValues(start.toDouble(), end.toDouble());
      });
    }
  }

  int get selectedPageCount => endPage - startPage + 1;
  double get selectionPercentage => (selectedPageCount / widget.totalPages) * 100;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AlertDialog(
      backgroundColor: colorScheme.surface,
      title: Text(
        'Select Download Range',
        style: TextStyleConst.headingMedium.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Content: ${widget.contentTitle}',
                    style: TextStyleConst.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total Pages: ${widget.totalPages}',
                    style: TextStyleConst.bodySmall.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Selection summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    'Selected: Pages $startPage to $endPage',
                    style: TextStyleConst.bodyLarge.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$selectedPageCount pages (${selectionPercentage.toStringAsFixed(1)}%)',
                    style: TextStyleConst.bodySmall.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Range slider
            Text(
              'Use slider to select range:',
              style: TextStyleConst.bodyMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: colorScheme.primary,
                inactiveTrackColor: colorScheme.onSurface.withValues(alpha: 0.4),
                thumbColor: colorScheme.primary,
                overlayColor: colorScheme.primary.withValues(alpha: 0.2),
                valueIndicatorColor: colorScheme.primary,
                valueIndicatorTextStyle: TextStyleConst.bodySmall.copyWith(
                  color: colorScheme.onPrimary,
                ),
              ),
              child: RangeSlider(
                values: _currentRangeValues,
                min: 1,
                max: widget.totalPages.toDouble(),
                divisions: widget.totalPages - 1,
                labels: RangeLabels(
                  startPage.toString(),
                  endPage.toString(),
                ),
                onChanged: (values) {
                  setState(() {
                    _currentRangeValues = values;
                  });
                  _updateFromSlider();
                },
              ),
            ),
            const SizedBox(height: 20),

            // Manual input fields
            Text(
              'Or enter manually:',
              style: TextStyleConst.bodyMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    style: TextStyleConst.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Start Page',
                      labelStyle: TextStyleConst.bodySmall.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colorScheme.primary, width: 2),
                      ),
                    ),
                    onChanged: (_) => _updateFromTextFields(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _endController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    style: TextStyleConst.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      labelText: 'End Page',
                      labelStyle: TextStyleConst.bodySmall.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colorScheme.primary, width: 2),
                      ),
                    ),
                    onChanged: (_) => _updateFromTextFields(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quick selection buttons
            Text(
              'Quick selections:',
              style: TextStyleConst.bodyMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickSelectChip('All Pages', 1, widget.totalPages, context),
                _buildQuickSelectChip('First Half', 1, (widget.totalPages / 2).round(), context),
                _buildQuickSelectChip('Second Half', (widget.totalPages / 2).round() + 1, widget.totalPages, context),
                _buildQuickSelectChip('First 10', 1, (widget.totalPages >= 10) ? 10 : widget.totalPages, context),
                _buildQuickSelectChip('Last 10', (widget.totalPages >= 10) ? widget.totalPages - 9 : 1, widget.totalPages, context),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyleConst.bodyMedium.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            widget.onRangeSelected(startPage, endPage);
            Navigator.pop(context);
          },
          icon: const Icon(Icons.download),
          label: Text('Download Range'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickSelectChip(String label, int start, int end, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = startPage == start && endPage == end;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          startPage = start;
          endPage = end;
          _currentRangeValues = RangeValues(start.toDouble(), end.toDouble());
          _updateControllers();
        });
      },
      backgroundColor: colorScheme.surfaceContainerHighest,
      selectedColor: colorScheme.primary.withValues(alpha: 0.2),
      labelStyle: TextStyleConst.bodySmall.copyWith(
        color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.7),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? colorScheme.primary : colorScheme.outline,
      ),
    );
  }
}
