import 'package:flutter/material.dart';

/// Alphabet filter widget for A-Z list
/// Displays A-Z letters + # + 0-9 as selectable chips
class AlphabetFilterWidget extends StatelessWidget {
  final String? selectedLetter;
  final ValueChanged<String?> onLetterSelected;

  // All available alphabet options
  static const List<String> _alphabetOptions = [
    '#',
    '0-9',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
  ];

  // Map display letters to URL parameters
  static const Map<String, String> _letterToParam = {
    '#': '.',
    '0-9': '0-9',
    // A-Z maps to themselves
  };

  const AlphabetFilterWidget({
    super.key,
    required this.selectedLetter,
    required this.onLetterSelected,
  });

  /// Convert display letter to URL parameter
  String _getParam(String letter) {
    return _letterToParam[letter] ?? letter;
  }

  /// Convert URL parameter to display letter
  String _getDisplayLetter(String? param) {
    if (param == null || param.isEmpty) return '';

    // Find by value
    for (final entry in _letterToParam.entries) {
      if (entry.value == param) return entry.key;
    }
    return param;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displaySelected = _getDisplayLetter(selectedLetter);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'Filter by Letter',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // Alphabet chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: _alphabetOptions.map((letter) {
              final isSelected = letter == displaySelected;
              return _buildLetterChip(
                context: context,
                letter: letter,
                isSelected: isSelected,
              );
            }).toList(),
          ),

          // Clear filter button (if selected)
          if (selectedLetter != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => onLetterSelected(null),
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear Filter'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLetterChip({
    required BuildContext context,
    required String letter,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected ? theme.colorScheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () {
          final param = _getParam(letter);
          // Toggle selection
          onLetterSelected(isSelected ? null : param);
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  isSelected ? theme.colorScheme.primary : theme.dividerColor,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              letter,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact version for smaller screens
class CompactAlphabetFilterWidget extends StatelessWidget {
  final String? selectedLetter;
  final ValueChanged<String?> onLetterSelected;

  // Map display letters to URL parameters
  static const Map<String, String> _letterToParam = {
    '#': '.',
    '0-9': '0-9',
  };

  const CompactAlphabetFilterWidget({
    super.key,
    required this.selectedLetter,
    required this.onLetterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 28, // #, 0-9, A-Z
        itemBuilder: (context, index) {
          String letter;
          if (index == 0) {
            letter = '#';
          } else if (index == 1) {
            letter = '0-9';
          } else {
            letter = String.fromCharCode(65 + index - 2); // A-Z
          }

          final param = _letterToParam[letter] ?? letter;
          final isSelected = param == selectedLetter;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Material(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => onLetterSelected(isSelected ? null : param),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    letter,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
