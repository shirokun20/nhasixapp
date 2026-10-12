// Shared version comparison for source configs and app updates.
//
// Pure Dart (no Flutter) so settings UI and [UpdateService] share one
// source of truth. Tolerates odd strings: unparsable → unknown (never
// claims an update falsely).
enum SourceVersionComparison { newer, same, older, unknown }

enum SourceVersionStatus {
  updateAvailable,
  upToDate,
  downgrade,
  notInstalled,
  unknown,
}

// Returns [SourceVersionComparison.newer] when [candidate] is newer than
// [installed]. Either side null/empty/unparsable → unknown.
SourceVersionComparison compareSourceVersions(
  String? installed,
  String? candidate,
) {
  final installedParts = _numericParts(installed);
  final candidateParts = _numericParts(candidate);
  if (installedParts == null || candidateParts == null) {
    return SourceVersionComparison.unknown;
  }
  final length = installedParts.length > candidateParts.length
      ? installedParts.length
      : candidateParts.length;
  for (var i = 0; i < length; i++) {
    final a = i < installedParts.length ? installedParts[i] : 0;
    final b = i < candidateParts.length ? candidateParts[i] : 0;
    if (b > a) return SourceVersionComparison.newer;
    if (b < a) return SourceVersionComparison.older;
  }
  return SourceVersionComparison.same;
}

// High-level status for the source install UI.
SourceVersionStatus resolveSourceVersionStatus({
  required String? installedVersion,
  required String? candidateVersion,
}) {
  final candidate = candidateVersion?.trim();
  if (candidate == null || candidate.isEmpty) {
    return SourceVersionStatus.unknown;
  }
  final installed = installedVersion?.trim();
  if (installed == null || installed.isEmpty) {
    return SourceVersionStatus.notInstalled;
  }
  return switch (compareSourceVersions(installed, candidate)) {
    SourceVersionComparison.newer => SourceVersionStatus.updateAvailable,
    SourceVersionComparison.same => SourceVersionStatus.upToDate,
    SourceVersionComparison.older => SourceVersionStatus.downgrade,
    SourceVersionComparison.unknown => SourceVersionStatus.unknown,
  };
}

// `true` when [candidate] is strictly newer than [installed`].
// ponytail: pre-release ordering (`-beta` < release) not modeled; add when
// source versions actually use pre-release tags.
bool isCandidateNewer(String? installed, String? candidate) =>
    compareSourceVersions(installed, candidate) ==
    SourceVersionComparison.newer;

// Stable update-first ordering: items whose candidate is newer than the
// installed version come first; everything else keeps its relative order.
// Pure (takes version readers) so UI lists and unit tests share it.
List<T> sortUpdateFirst<T>(
  Iterable<T> items, {
  required String? Function(T item) installedVersionOf,
  required String? Function(T item) candidateVersionOf,
}) {
  bool hasUpdate(T item) =>
      resolveSourceVersionStatus(
        installedVersion: installedVersionOf(item),
        candidateVersion: candidateVersionOf(item),
      ) ==
      SourceVersionStatus.updateAvailable;
  final indexed = items.toList().asMap().entries.toList();
  indexed.sort((a, b) {
    final rank =
        (hasUpdate(a.value) ? 0 : 1).compareTo(hasUpdate(b.value) ? 0 : 1);
    return rank != 0 ? rank : a.key.compareTo(b.key);
  });
  return [for (final entry in indexed) entry.value];
}

List<int>? _numericParts(String? version) {
  final raw = version?.trim();
  if (raw == null || raw.isEmpty) return null;
  var clean = raw;
  if (clean.startsWith('v') || clean.startsWith('V')) {
    clean = clean.substring(1);
  }
  clean = clean.split('+').first.trim();
  if (clean.isEmpty) return null;
  final parts = <int>[];
  for (final chunk in clean.split('.')) {
    final segment = chunk.trim();
    if (segment.isEmpty) return null;
    // Strip pre-release/build suffix: `2-beta` → 2.
    final match = RegExp(r'^\d+').firstMatch(segment);
    if (match == null) return null;
    parts.add(int.parse(match.group(0)!));
  }
  return parts.isEmpty ? null : parts;
}
