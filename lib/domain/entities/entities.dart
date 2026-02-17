// Domain Entities Export File
// Core entities from kuron_core package
export 'package:kuron_core/kuron_core.dart' show Content, Tag, TagType;

// App-specific extensions for core entities
export 'package:nhasixapp/domain/extensions/content_extensions.dart';
export 'package:nhasixapp/domain/extensions/tag_extensions.dart';

// App-specific entities (not in kuron_core)
export 'search_filter.dart';
export 'user_preferences.dart';
export 'download_status.dart';
export 'history.dart';
export 'reading_statistics.dart';
export 'reader_position.dart';

// KomikTap Navigation List entities (NEW)
export 'content_list_type.dart';
export 'genre.dart';
export 'pagination_info.dart';
