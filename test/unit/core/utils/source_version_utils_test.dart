import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/core/utils/source_version_utils.dart';

void main() {
  group('compareSourceVersions', () {
    test('detects newer candidate (komiktap 1.1.1 vs 1.1.2)', () {
      expect(
        compareSourceVersions('1.1.1', '1.1.2'),
        SourceVersionComparison.newer,
      );
    });

    test('same versions compare equal', () {
      expect(
        compareSourceVersions('1.1.2', '1.1.2'),
        SourceVersionComparison.same,
      );
    });

    test('detects downgrade', () {
      expect(
        compareSourceVersions('1.1.2', '1.1.1'),
        SourceVersionComparison.older,
      );
    });

    test('handles different segment lengths', () {
      expect(
        compareSourceVersions('1.0', '1.0.1'),
        SourceVersionComparison.newer,
      );
      expect(
        compareSourceVersions('1.0.1', '1.0'),
        SourceVersionComparison.older,
      );
    });

    test('unparsable strings are unknown', () {
      expect(
        compareSourceVersions('unknown', '1.1.2'),
        SourceVersionComparison.unknown,
      );
      expect(
        compareSourceVersions('1.1.1', 'unknown'),
        SourceVersionComparison.unknown,
      );
      expect(
        compareSourceVersions(null, '1.1.2'),
        SourceVersionComparison.unknown,
      );
      expect(
        compareSourceVersions('1.1.1', null),
        SourceVersionComparison.unknown,
      );
    });

    test('tolerates v-prefix, build metadata, and pre-release suffix', () {
      expect(
        compareSourceVersions('v1.1.1', 'v1.1.2'),
        SourceVersionComparison.newer,
      );
      expect(
        compareSourceVersions('1.1.1+11', '1.1.2+3'),
        SourceVersionComparison.newer,
      );
      expect(
        compareSourceVersions('1.1.1', '1.1.2-beta'),
        SourceVersionComparison.newer,
      );
    });
  });

  group('resolveSourceVersionStatus', () {
    test('maps comparison to UI status', () {
      expect(
        resolveSourceVersionStatus(
          installedVersion: '1.1.1',
          candidateVersion: '1.1.2',
        ),
        SourceVersionStatus.updateAvailable,
      );
      expect(
        resolveSourceVersionStatus(
          installedVersion: '1.1.2',
          candidateVersion: '1.1.2',
        ),
        SourceVersionStatus.upToDate,
      );
      expect(
        resolveSourceVersionStatus(
          installedVersion: '1.1.2',
          candidateVersion: '1.1.1',
        ),
        SourceVersionStatus.downgrade,
      );
      expect(
        resolveSourceVersionStatus(
          installedVersion: null,
          candidateVersion: '1.1.2',
        ),
        SourceVersionStatus.notInstalled,
      );
      expect(
        resolveSourceVersionStatus(
          installedVersion: '1.1.1',
          candidateVersion: 'garbage!!',
        ),
        SourceVersionStatus.unknown,
      );
    });
  });

  group('sortUpdateFirst', () {
    test('moves updatable items first, keeps rest stable', () {
      final items = [
        ('a', '1.1.1', '1.1.1'), // up-to-date
        ('b', '1.1.1', '1.1.2'), // update
        ('c', null, '2.0.0'), // new install, not an update
        ('d', '1.1.1', '1.1.5'), // update
      ];
      final sorted = sortUpdateFirst(
        items,
        installedVersionOf: (item) => item.$2,
        candidateVersionOf: (item) => item.$3,
      );
      expect(
        [for (final item in sorted) item.$1],
        ['b', 'd', 'a', 'c'],
      );
    });
  });
}
