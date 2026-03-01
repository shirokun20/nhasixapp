/// CSS selector-based HTML parser for scraper-type sources.
///
/// Wraps the `html` package to evaluate CSS selectors and extract text
/// or attribute values from HTML documents.
library;

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:logger/logger.dart';

import '../models/source_config_runtime.dart';

class GenericHtmlParser {
  final Logger _logger;

  GenericHtmlParser({required Logger logger}) : _logger = logger;

  /// Parse [htmlString] into a [dom.Document].
  dom.Document parse(String htmlString) => html_parser.parse(htmlString);

  /// Extract a single string value from [document] using [selector].
  String? extractString(dom.Document document, FieldSelector selector) {
    try {
      final element = document.querySelector(selector.selector);
      if (element == null) return selector.fallback;
      final value = selector.attribute != null
          ? element.attributes[selector.attribute]
          : element.text.trim();
      if (value == null || value.isEmpty) return selector.fallback;
      if (selector.regex != null) return _applyRegex(value, selector.regex!);
      return value;
    } catch (e) {
      _logger.w('GenericHtmlParser: failed to extract "${selector.selector}"',
          error: e);
      return selector.fallback;
    }
  }

  /// Extract a list of string values from [document] using [selector].
  List<String> extractList(dom.Document document, FieldSelector selector) {
    try {
      final elements = document.querySelectorAll(selector.selector);
      return elements
          .map((el) => selector.attribute != null
              ? (el.attributes[selector.attribute] ?? '')
              : el.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      _logger.w(
          'GenericHtmlParser: failed to extract list "${selector.selector}"',
          error: e);
      return const [];
    }
  }

  /// Extract a list of [dom.Element] nodes matching [selector].
  List<dom.Element> selectAll(dom.Document document, String cssSelector) {
    try {
      return document.querySelectorAll(cssSelector);
    } catch (e) {
      _logger.w('GenericHtmlParser: querySelectorAll failed for "$cssSelector"',
          error: e);
      return const [];
    }
  }

  /// Extract attribute or text from a single [dom.Element] using [selector].
  String? extractFromElement(dom.Element element, FieldSelector selector) {
    try {
      final value = selector.attribute != null
          ? element.attributes[selector.attribute]
          : element.text.trim();
      if (value == null || value.isEmpty) return selector.fallback;
      if (selector.regex != null) return _applyRegex(value, selector.regex!);
      return value;
    } catch (e) {
      return selector.fallback;
    }
  }

  // ── Private ────────────────────────────────────────────────────────────────

  String? _applyRegex(String input, String pattern) {
    try {
      final match = RegExp(pattern).firstMatch(input);
      if (match == null) return null;
      return match.groupCount > 0 ? match.group(1) : match.group(0);
    } catch (e) {
      return null;
    }
  }
}
