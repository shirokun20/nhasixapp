/// Core library for Kuron multi-source content app.
/// This library provides shared interfaces, entities, and value objects
/// that are used across different content source implementations.
library;

// Sources
export 'src/sources/content_source.dart';
export 'src/sources/search_capabilities.dart';
export 'src/sources/content_source_registry.dart';

// Entities
export 'src/entities/content.dart';
export 'src/entities/tag.dart';
export 'src/entities/search_filter.dart';
export 'src/entities/content_list_result.dart';
export 'src/entities/filter_item.dart';
export 'src/entities/content_metadata.dart';
export 'src/entities/chapter.dart';
export 'src/entities/chapter_data.dart';

// Value Objects
export 'src/value_objects/sort_option.dart';
export 'src/value_objects/popular_timeframe.dart';

// Enums
export 'src/enums/source_type.dart';
