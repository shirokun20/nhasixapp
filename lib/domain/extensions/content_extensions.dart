import 'dart:io';
import 'package:kuron_core/kuron_core.dart';
import 'package:path/path.dart' as path;

/// App-specific extension methods for kuron_core Content entity.
///
/// These methods are specific to this app and not part of the core package.
extension ContentAppExtensions on Content {
  /// Derive the content directory path from imageUrls
  ///
  /// This extracts the local filesystem path to the content directory
  /// by looking at the first image URL and navigating up to the parent folder.
  /// If the parent is an "images" subfolder, it goes up one more level.
  ///
  /// Returns null if imageUrls is empty or doesn't contain local file paths.
  String? get derivedContentPath {
    if (imageUrls.isEmpty) return null;

    final imagePath = imageUrls.first;
    // Only process local file paths
    if (imagePath.startsWith('http')) return null;

    try {
      var parentDir = File(imagePath).parent;
      // If parent is "images" subfolder, go up one more level to content dir
      if (path.basename(parentDir.path) == 'images') {
        return parentDir.parent.path;
      }
      return parentDir.path;
    } catch (e) {
      return null;
    }
  }

  /// Check if content is NSFW based on tags
  bool get isNsfw {
    const nsfwTags = [
      'lolicon',
      'shotacon',
      'rape',
      'netorare',
      'ugly bastard'
    ];
    return tags.any((tag) => nsfwTags.contains(tag.name.toLowerCase()));
  }

  /// Legacy source field accessor (maps to sourceId)
  /// For backward compatibility during migration
  String get source => sourceId;
}
