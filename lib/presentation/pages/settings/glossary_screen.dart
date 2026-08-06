import 'package:flutter/material.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/domain/entities/glossary.dart';

/// Learning glossary review: list entries, delete individually.
class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  late Future<List<GlossaryEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = getIt<GlossaryRepository>().getAll();
  }

  void _reload() {
    setState(() {
      _future = getIt<GlossaryRepository>().getAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Glossary')),
      body: FutureBuilder<List<GlossaryEntry>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return const Center(
              child: Text(
                'No glossary entries yet.\nLong-press a translated bubble to save one.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final e = entries[index];
              return ListTile(
                title: Text(e.translatedText,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(e.sourceText.isEmpty
                    ? '${e.contentId} • page ${e.pageIndex}'
                    : '${e.sourceText}\n${e.contentId} • page ${e.pageIndex}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await getIt<GlossaryRepository>().delete(e.id);
                    _reload();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
