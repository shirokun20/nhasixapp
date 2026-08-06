import 'package:equatable/equatable.dart';

/// A saved vocabulary/phrase from a translated bubble, for learning review.
class GlossaryEntry extends Equatable {
  const GlossaryEntry({
    required this.id,
    required this.sourceText,
    required this.translatedText,
    required this.contentId,
    required this.pageIndex,
    required this.timestamp,
  });

  final String id;
  final String sourceText;
  final String translatedText;
  final String contentId;
  final int pageIndex;
  final int timestamp; // Unix seconds

  factory GlossaryEntry.fromJson(Map<String, dynamic> json) {
    return GlossaryEntry(
      id: json['id'] as String,
      sourceText: json['sourceText'] as String,
      translatedText: json['translatedText'] as String,
      contentId: json['contentId'] as String,
      pageIndex: json['pageIndex'] as int,
      timestamp: json['timestamp'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceText': sourceText,
        'translatedText': translatedText,
        'contentId': contentId,
        'pageIndex': pageIndex,
        'timestamp': timestamp,
      };

  @override
  List<Object?> get props =>
      [id, sourceText, translatedText, contentId, pageIndex, timestamp];
}

/// Storage + queries for glossary entries (SharedPreferences JSON list).
abstract interface class GlossaryRepository {
  Future<List<GlossaryEntry>> getAll();
  Future<void> save(GlossaryEntry entry);
  Future<void> delete(String id);
}
