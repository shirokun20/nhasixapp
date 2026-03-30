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
  ///
  /// If [selector.regex] is provided and selector has multiple matching elements,
  /// scans through them and returns the first value that matches the regex.
  String? extractString(dom.Document document, FieldSelector selector) {
    try {
      if (selector.regex != null) {
        // For regex extraction, scan all matching elements and return the first
        // value that matches the regex. This is useful for repeated selectors
        // where only one node contains the desired token.
        final elements = document.querySelectorAll(selector.selector);
        _logger.d(
            'GenericHtmlParser.extractString: selector="${selector.selector}", regex=${selector.regex}, found ${elements.length} elements');

        for (final element in elements) {
          final value = selector.attribute != null
              ? element.attributes[selector.attribute]
              : element.text.trim();
          if (value == null || value.isEmpty) continue;

          final matched = _applyRegex(value, selector.regex!);
          if (matched != null && matched.isNotEmpty) {
            _logger.d(
                'GenericHtmlParser.extractString: regex matched on element: "$value" → "$matched"');
            return matched;
          }
        }
        _logger.w(
            'GenericHtmlParser.extractString: regex did not match any element for "${selector.selector}"');
        return selector.fallback;
      }

      final element = document.querySelector(selector.selector);
      if (element == null) {
        _logger.t(
            'GenericHtmlParser.extractString: selector "${selector.selector}" matched no elements');
        return selector.fallback;
      }
      final value = selector.attribute != null
          ? element.attributes[selector.attribute]
          : element.text.trim();
      if (value == null || value.isEmpty) {
        _logger.t(
            'GenericHtmlParser.extractString: selector "${selector.selector}" matched element but value empty');
        return selector.fallback;
      }
      _logger.d(
          'GenericHtmlParser.extractString: selector="${selector.selector}" → "$value"');
      return value;
    } catch (e) {
      _logger.w('GenericHtmlParser: failed to extract "${selector.selector}"',
          error: e);
      return selector.fallback;
    }
  }

  /// Extract a list of string values from [document] using [selector].
  ///
  /// If [selector.regex] is provided, applies regex to each extracted value
  /// and keeps only values where regex produces a match (group 1 if available,
  /// else group 0). This is critical for multi-extraction with regex filtering
  /// (e.g. tags where you want "ahegao" from "ahegao (123)").
  List<String> extractList(dom.Document document, FieldSelector selector) {
    try {
      final elements = document.querySelectorAll(selector.selector);
      _logger.d(
          'GenericHtmlParser.extractList: selector="${selector.selector}", multi=true, regex=${selector.regex}, found ${elements.length} elements');

      final rawValues = elements
          .map((el) => selector.attribute != null
              ? (el.attributes[selector.attribute] ?? '')
              : el.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      if (selector.regex == null) {
        _logger.d(
            'GenericHtmlParser.extractList: no regex, returning ${rawValues.length} raw values');
        return rawValues;
      }

      // Apply regex to each value
      final regexed = <String>[];
      for (final value in rawValues) {
        final matched = _applyRegex(value, selector.regex!);
        if (matched != null && matched.isNotEmpty) {
          regexed.add(matched);
          _logger.t(
              'GenericHtmlParser.extractList: regex matched: "$value" → "$matched"');
        } else {
          _logger.t(
              'GenericHtmlParser.extractList: regex rejected: "$value" (pattern: ${selector.regex})');
        }
      }
      _logger.d(
          'GenericHtmlParser.extractList: regex-filtered ${rawValues.length} → ${regexed.length} values');
      return regexed;
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

  /// Extract attribute or text from an [element] using [selector].
  ///
  /// The CSS [FieldSelector.selector] is first evaluated as a child query
  /// inside [element] (e.g. container = `.utao`, field selector = `a.series`).
  /// If no child is found the value is read from [element] itself — this
  /// handles the rare case where the container element IS the target node.
  String? extractFromElement(dom.Element element, FieldSelector selector) {
    try {
      final child = element.querySelector(selector.selector);
      final target = child ?? element;
      final value = selector.attribute != null
          ? target.attributes[selector.attribute]
          : target.text.trim();
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
