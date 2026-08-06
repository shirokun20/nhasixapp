import 'package:flutter/material.dart';

/// Full-screen one-time tutorial overlay explaining the AI-translate toolbar.
/// Dark translucent barrier over the whole reader + centered info card.
class ReaderAiTutorialOverlay extends StatelessWidget {
  const ReaderAiTutorialOverlay({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.black.withValues(alpha: 0.78),
      child: SafeArea(
        child: Stack(
          children: [
            // Tap anywhere to dismiss
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onComplete,
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 40),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'AI Translate',
                        style: theme.textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.touch_app,
                              size: 14, color: theme.colorScheme.outline),
                          const SizedBox(width: 4),
                          Text('Tap di mana saja untuk tutup',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _TutorialRow(
                        icon: Icons.auto_awesome,
                        color: Colors.amber,
                        title: '✨ Translate halaman',
                        desc:
                            'Deteksi bubble otomatis → terjemahan di-overlay '
                            'di atas teks asli. Tap lagi untuk hide/show.',
                      ),
                      const SizedBox(height: 14),
                      _TutorialRow(
                        icon: Icons.draw_outlined,
                        color: Colors.blueAccent,
                        title: '✏️ Draw bubbles',
                        desc:
                            'Koreksi manual. Drag untuk tambah bubble (merah), '
                            '🛰 Detect untuk lihat deteksi ONNX (biru). Done '
                            'mengunci tapi bubble tetap tampil.',
                      ),
                      const SizedBox(height: 14),
                      _TutorialRow(
                        icon: Icons.delete_sweep_outlined,
                        color: Colors.redAccent,
                        title: '🗑 Clear',
                        desc: 'Hapus hasil translate + semua bubble referensi.',
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: onComplete,
                        child: const Text('Paham!'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialRow extends StatelessWidget {
  const _TutorialRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(desc, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}