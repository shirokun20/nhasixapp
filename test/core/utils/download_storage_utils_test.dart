import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/core/utils/download_storage_utils.dart';

void main() {
  group('DownloadStorageUtils.getSafeTitleFromMetadata', () {
    test('returns correct title when metadata is completely valid', () {
      final metadata = {
        'title': 'Original Title',
        'id': 'original-slug',
      };
      
      final result = DownloadStorageUtils.getSafeTitleFromMetadata(metadata, 'folderHash123');
      expect(result, 'Original Title');
    });

    test('formats the original id (slug) when title is an empty string', () {
      final metadata = {
        'title': '',
        'id': 'my-beautiful-chapter-1',
      };
      
      final result = DownloadStorageUtils.getSafeTitleFromMetadata(metadata, 'folderHash123');
      
      // Should capitalize parts of original slug and replace hyphens with spaces
      expect(result, 'My Beautiful Chapter 1');
    });

    test('formats the original id when title is suspected ciphertext (no spaces and > 50 length)', () {
      final ciphertext = List.generate(60, (_) => 'a').join('');
      
      final metadata = {
        'title': ciphertext,
        'id': 'corrupted-title-chapter-2',
      };
      
      final result = DownloadStorageUtils.getSafeTitleFromMetadata(metadata, 'folderHash123');
      
      expect(result, 'Corrupted Title Chapter 2');
    });

    test('returns the formatted contentId when metadata is totally null', () {
      // If metadata is totally null, there is no ID to fallback to besides the contentId
      final result = DownloadStorageUtils.getSafeTitleFromMetadata(null, 'some-folder-hash');
      
      // contentId 'some-folder-hash' gets formatted
      expect(result, 'Some Folder Hash');
    });

    test('returns unaffected title if it is just a short unspaced word (not ciphertext)', () {
      final metadata = {
        'title': 'ShortNoSpaces',
        'id': 'some-chapter-slug',
      };
      
      final result = DownloadStorageUtils.getSafeTitleFromMetadata(metadata, 'folderHash123');
      expect(result, 'ShortNoSpaces');
    });

    test('handles empty original id gracefully and falls back to formatting contentId (folder name)', () {
      final metadata = {
        'title': '',
        'id': '',
      };
      
      // Since title is empty AND id is empty, it relies on contentId
      final result = DownloadStorageUtils.getSafeTitleFromMetadata(metadata, 'fallback-folder-hash');
      expect(result, 'Fallback Folder Hash');
    });

    test('returns original id unchanged if it does not contain hyphens', () {
      final metadata = {
        'title': '',
        'id': 'nospacesslug',
      };
      
      final result = DownloadStorageUtils.getSafeTitleFromMetadata(metadata, 'folderHash123');
      // formatSlug leaves Strings without hyphens unchanged
      expect(result, 'nospacesslug');
    });
  });
}
