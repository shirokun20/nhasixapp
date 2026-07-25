import 'package:flutter/material.dart';

class TranslationStyle {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final bool requiresConfirm;

  const TranslationStyle({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    this.requiresConfirm = false,
  });

  static const all = [
    TranslationStyle(
      id: 'literal',
      label: 'Literal',
      description: 'Terjemahan akurat kata per kata',
      icon: Icons.translate,
    ),
    TranslationStyle(
      id: 'natural',
      label: 'Natural',
      description: 'Bahasa Indonesia sehari-hari yang enak dibaca',
      icon: Icons.chat_bubble_outline,
    ),
    TranslationStyle(
      id: 'gaul',
      label: 'Gaul',
      description: 'Santai banget, gue/lo, wkwk',
      icon: Icons.mood,
    ),
    TranslationStyle(
      id: 'perwibuan',
      label: 'Perwibuan',
      description: 'Bahasa keraton nan agung, hamba paduka',
      icon: Icons.account_balance,
    ),
    TranslationStyle(
      id: 'kasar',
      label: 'Kasar 🔥',
      description: 'Blak-blakan, kata keras ringan (18+)',
      icon: Icons.whatshot,
      requiresConfirm: true,
    ),
    TranslationStyle(
      id: 'emakGosip',
      label: 'Emak Gosip 🧧',
      description: 'Dramatis, ya ampun tau nggak sih!',
      icon: Icons.campaign,
    ),
    TranslationStyle(
      id: 'bapack',
      label: 'Bapack ☕',
      description: 'Gaya bapak-bapak WA, ngopi dulu ngab',
      icon: Icons.local_cafe,
    ),
    TranslationStyle(
      id: 'betawi',
      label: 'Betawi 🦅',
      description: 'Gaya Betawi asli plus pantun',
      icon: Icons.location_city,
    ),
  ];
}

class TranslationStylePicker extends StatelessWidget {
  final String selectedStyle;
  final ValueChanged<String> onChanged;
  final bool compact;

  const TranslationStylePicker({
    super.key,
    required this.selectedStyle,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Gaya Terjemahan',
                style: theme.textTheme.titleSmall),
          ),
        SizedBox(
          height: compact ? 40 : 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: TranslationStyle.all.map((style) {
              final isSelected = style.id == selectedStyle;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: compact
                    ? ChoiceChip(
                        label: Text(style.label, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (_) => onChanged(style.id),
                      )
                    : ActionChip(
                        avatar: Icon(style.icon, size: 18,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant),
                        label: Text(style.label),
                        onPressed: () {
                          if (style.requiresConfirm) {
                            _confirmStyle(context, style);
                          } else {
                            onChanged(style.id);
                          }
                        },
                        side: isSelected
                            ? BorderSide(color: theme.colorScheme.primary)
                            : null,
                      ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _confirmStyle(BuildContext context, TranslationStyle style) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Konfirmasi: ${style.label}'),
        content: Text(
          'Mode "${style.label}" menggunakan kata-kata keras. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onChanged(style.id);
            },
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
  }
}
