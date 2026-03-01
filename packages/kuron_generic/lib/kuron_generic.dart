/// kuron_generic — Config-driven generic HTTP source for Kuron app.
///
/// Provides [GenericHttpSource] which implements [ContentSource] based on
/// a JSON config file (template URLs, JSONPath/CSS selector parsers,
/// filter transformers). No Dart code changes needed to add a new provider —
/// only a new JSON config.
library;

export 'src/adapters/generic_adapter.dart';
export 'src/adapters/generic_rest_adapter.dart';
export 'src/adapters/generic_scraper_adapter.dart';
export 'src/filters/generic_filter_transformer.dart';
export 'src/generic_http_source.dart';
export 'src/generic_source_factory.dart';
export 'src/models/source_config_runtime.dart';
export 'src/parsers/generic_html_parser.dart';
export 'src/parsers/generic_json_parser.dart';
export 'src/url_builder/generic_url_builder.dart';
