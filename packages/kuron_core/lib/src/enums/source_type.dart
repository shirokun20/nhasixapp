enum SourceType {
  nhentai('nhentai'),
  crotpedia('crotpedia'),
  komiktap('komiktap');

  final String id;
  const SourceType(this.id);

  static SourceType? fromId(String id) {
    try {
      return SourceType.values.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
