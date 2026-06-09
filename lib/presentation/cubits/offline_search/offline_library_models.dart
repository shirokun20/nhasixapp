import 'package:equatable/equatable.dart';
import 'package:kuron_core/kuron_core.dart';

enum OfflineLibrarySortMode {
  date,
  title,
  imageCount,
}

enum OfflineSourceBucketKind {
  all,
  installed,
  local,
  other,
}

class OfflineSourceFilterOption extends Equatable {
  const OfflineSourceFilterOption({
    required this.id,
    required this.kind,
    this.sourceId,
    this.displayName,
  });

  static const String allId = '__all__';
  static const String localId = '__local__';
  static const String otherId = '__other__';

  final String id;
  final OfflineSourceBucketKind kind;
  final String? sourceId;
  final String? displayName;

  bool get isAll => id == allId;

  @override
  List<Object?> get props => [id, kind, sourceId, displayName];
}

class OfflineLibraryItemData extends Equatable {
  const OfflineLibraryItemData({
    required this.content,
    required this.rawSourceId,
    required this.sourceBucketKind,
    required this.sourceDisplayName,
    required this.sourceFilterId,
    required this.imageCount,
    required this.fileSizeBytes,
    required this.sortDate,
    this.resolvedPath,
    this.parentId,
    this.parentTitle,
    this.chapterTitle,
    this.chapterIndex,
  });

  final Content content;
  final String rawSourceId;
  final OfflineSourceBucketKind sourceBucketKind;
  final String sourceDisplayName;
  final String sourceFilterId;
  final int imageCount;
  final int fileSizeBytes;
  final DateTime sortDate;
  final String? resolvedPath;
  final String? parentId;
  final String? parentTitle;
  final String? chapterTitle;
  final int? chapterIndex;

  bool get hasParentContext =>
      parentId != null &&
      parentId!.isNotEmpty &&
      parentTitle != null &&
      parentTitle!.isNotEmpty;

  String get stableId => content.id;

  String get childLabel {
    final label = chapterTitle?.trim();
    if (label != null && label.isNotEmpty) {
      return label;
    }
    return content.title;
  }

  OfflineLibraryItemData copyWith({
    Content? content,
    String? rawSourceId,
    OfflineSourceBucketKind? sourceBucketKind,
    String? sourceDisplayName,
    String? sourceFilterId,
    int? imageCount,
    int? fileSizeBytes,
    DateTime? sortDate,
    String? resolvedPath,
    String? parentId,
    String? parentTitle,
    String? chapterTitle,
    int? chapterIndex,
  }) {
    return OfflineLibraryItemData(
      content: content ?? this.content,
      rawSourceId: rawSourceId ?? this.rawSourceId,
      sourceBucketKind: sourceBucketKind ?? this.sourceBucketKind,
      sourceDisplayName: sourceDisplayName ?? this.sourceDisplayName,
      sourceFilterId: sourceFilterId ?? this.sourceFilterId,
      imageCount: imageCount ?? this.imageCount,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      sortDate: sortDate ?? this.sortDate,
      resolvedPath: resolvedPath ?? this.resolvedPath,
      parentId: parentId ?? this.parentId,
      parentTitle: parentTitle ?? this.parentTitle,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      chapterIndex: chapterIndex ?? this.chapterIndex,
    );
  }

  @override
  List<Object?> get props => [
        content,
        rawSourceId,
        sourceBucketKind,
        sourceDisplayName,
        sourceFilterId,
        imageCount,
        fileSizeBytes,
        sortDate,
        resolvedPath,
        parentId,
        parentTitle,
        chapterTitle,
        chapterIndex,
      ];
}

class OfflineLibraryGroupData extends Equatable {
  const OfflineLibraryGroupData({
    required this.groupKey,
    required this.parentId,
    required this.parentTitle,
    required this.rawSourceId,
    required this.sourceBucketKind,
    required this.sourceDisplayName,
    required this.sourceFilterId,
    required this.sortDate,
    required this.children,
    this.resolvedPath,
  });

  final String groupKey;
  final String parentId;
  final String parentTitle;
  final String rawSourceId;
  final OfflineSourceBucketKind sourceBucketKind;
  final String sourceDisplayName;
  final String sourceFilterId;
  final DateTime sortDate;
  final List<OfflineLibraryItemData> children;
  final String? resolvedPath;

  Content get previewContent => children.first.content;

  int get totalImageCount =>
      children.fold<int>(0, (sum, child) => sum + child.imageCount);

  int get totalFileSizeBytes =>
      children.fold<int>(0, (sum, child) => sum + child.fileSizeBytes);

  OfflineLibraryGroupData copyWith({
    DateTime? sortDate,
    List<OfflineLibraryItemData>? children,
    String? resolvedPath,
  }) {
    return OfflineLibraryGroupData(
      groupKey: groupKey,
      parentId: parentId,
      parentTitle: parentTitle,
      rawSourceId: rawSourceId,
      sourceBucketKind: sourceBucketKind,
      sourceDisplayName: sourceDisplayName,
      sourceFilterId: sourceFilterId,
      sortDate: sortDate ?? this.sortDate,
      children: children ?? this.children,
      resolvedPath: resolvedPath ?? this.resolvedPath,
    );
  }

  @override
  List<Object?> get props => [
        groupKey,
        parentId,
        parentTitle,
        rawSourceId,
        sourceBucketKind,
        sourceDisplayName,
        sourceFilterId,
        sortDate,
        children,
        resolvedPath,
      ];
}
