import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nhasixapp/core/utils/header_inspector.dart';

/// Centralized header inspect with in-flight dedup + bounded cache.
///  Widget no longer keeps per-state pending batch — single service owns it.
///  3 concurrent inspect same path → underlying `compute` only 1 call (shared future).

class HeaderInspectorService {
  HeaderInspectorService({
    Future<FileHeaderResult> Function(String path)? inspectImpl,
    this.maxCacheSize = 100,
  }) : _inspectImpl =
            inspectImpl ?? ((String p) => compute(inspectFileHeader, p));

  final Future<FileHeaderResult> Function(String path) _inspectImpl;
  final int maxCacheSize;

  final Map<String, FileHeaderResult> _cache = {};
  final Map<String, Future<FileHeaderResult>> _inFlight = {};

  int get cacheSize => _cache.length;
  int get inFlightCount => _inFlight.length;

  Future<FileHeaderResult> inspect(String path) {
    final cached = _cache[path];
    if (cached != null) return Future.value(cached);
    final flight = _inFlight[path];
    if (flight != null) return flight;

    final future = _inspectImpl(path).then((res) {
      _cache[path] = res;
      if (_cache.length > maxCacheSize) {
        _cache.remove(_cache.keys.first);
      }
      return res;
    }).whenComplete(() {
      _inFlight.remove(path);
    });

    _inFlight[path] = future;
    return future;
  }

  Future<Map<String, FileHeaderResult>> inspectBatch(List<String> paths) async {
    final unique = paths.toSet().toList();
    final results = await Future.wait(unique.map(inspect));
    final map = <String, FileHeaderResult>{};
    for (int i = 0; i < unique.length; i++) {
      map[unique[i]] = results[i];
    }
    return map;
  }

  void clearCache() {
    _cache.clear();
  }

  void clearForTesting() {
    _cache.clear();
    _inFlight.clear();
  }
}
