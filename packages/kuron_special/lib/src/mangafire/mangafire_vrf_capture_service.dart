import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:kuron_native/kuron_native.dart';

import 'mangafire_vrf_config.dart';
import 'mangafire_vrf_cache.dart';

class MangaFireVRFCaptureService {
  final MangaFireVRFConfig _config;
  final MangaFireVRFCache _cache;
  final Logger _logger;
  final String _logTag;
  bool _capturing = false;
  int _lastCaptureAt = 0;
  String? _lastTitleHid;

  MangaFireVRFCaptureService({
    required MangaFireVRFConfig config,
    required MangaFireVRFCache cache,
    required Logger logger,
    String sourceId = 'mangafire',
  })  : _config = config,
        _cache = cache,
        _logger = logger,
        _logTag = sourceId;

  Future<void> captureForPath(String path,
      {Map<String, dynamic>? requestParams}) async {
    if (_capturing) {
      _logger.d('$_logTag: capture in progress, waiting');
      while (_capturing) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
      if (_cache.getEntry(path) != null) return;
    }
    _capturing = true;
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (_lastCaptureAt > 0 && now - _lastCaptureAt < 3000) {
        await Future.delayed(
            Duration(milliseconds: 3000 - (now - _lastCaptureAt)));
      }
      await _doCapture(path, requestParams);
      _lastCaptureAt = DateTime.now().millisecondsSinceEpoch;
    } finally {
      _capturing = false;
    }
  }

  Future<void> warmup() async {
    if (_capturing) return;
    _capturing = true;
    try {
      final spaUrl = _config.captureUrl;
      _logger.i('$_logTag: warmup via SPA: $spaUrl (no cache write)');
      await KuronNative.instance.headlessGetClearance(
        url: spaUrl,
        script: '',
        timeoutMs: _config.captureTimeoutMs,
        captureDelayMs: 4000,
        captureUrlPattern: 'vrf=',
      );
    } finally {
      _capturing = false;
    }
  }

  static const _browseParams = {
    'keyword',
    'genres_in',
    'genres_ex',
    'types',
    'statuses',
    'demographics',
    'content_rating',
    'formats',
    'authors',
    'language',
  };

  static const _langButtonText = {
    'es': 'Spanish',
    'es-la': 'LATAM',
    'pt': 'Portuguese',
    'pt-br': '(Br)',
    'fr': 'French',
    'ja': 'Japanese',
  };

  String _spaUrlFor(String path, {Map<String, dynamic>? params}) {
    if (path.startsWith('/api/chapters/')) {
      final segs = path.split('/');
      final chapterId = segs.length >= 4 ? segs[3] : null;
      if (chapterId != null && _lastTitleHid != null) {
        return '${_config.captureUrl}title/$_lastTitleHid/chapter/$chapterId';
      }
      return _config.captureUrl;
    }

    if (path.startsWith('/api/titles/')) {
      final segs = path.split('/');
      if (segs.length >= 4 &&
          !path.contains('/chapters') &&
          !path.contains('/volumes')) {
        _lastTitleHid = segs[3];
        return '${_config.captureUrl}title/${segs[3]}';
      }
      final idx = segs.indexOf('titles');
      if (idx >= 0 && idx + 1 < segs.length) {
        _lastTitleHid = segs[idx + 1];
        final isChaptersOrVol =
            path.contains('/chapters') || path.contains('/volumes');
        if (isChaptersOrVol && params != null && params.containsKey('page')) {
          return '${_config.captureUrl}title/${segs[idx + 1]}?__page=${params['page']}';
        }
        return '${_config.captureUrl}title/${segs[idx + 1]}';
      }
    }

    if (path == '/api/titles' && params != null) {
      final browseKeys = params.keys
          .where((k) => _browseParams.contains(k.replaceAll('[]', '')))
          .toList();
      if (browseKeys.isNotEmpty) {
        final buf = StringBuffer('${_config.captureUrl}browse');
        bool first = true;
        for (final key in browseKeys) {
          final cleanKey = key.replaceAll('[]', '');
          final val = params[key];
          if (val is List) {
            for (final v in val) {
              buf.write(first ? '?' : '&');
              buf.write(
                  '${Uri.encodeQueryComponent(cleanKey)}=${Uri.encodeQueryComponent(v.toString())}');
              first = false;
            }
          } else {
            buf.write(first ? '?' : '&');
            buf.write(
                '${Uri.encodeQueryComponent(cleanKey)}=${Uri.encodeQueryComponent(val.toString())}');
            first = false;
          }
        }
        final page = params['page']?.toString();
        if (page != null) {
          buf.write(first ? '?' : '&');
          buf.write('page=${Uri.encodeQueryComponent(page)}');
        }
        return buf.toString();
      }

      if (params.containsKey('page')) {
        final page = params['page'].toString();
        return '${_config.captureUrl}?page=${Uri.encodeQueryComponent(page)}';
      }
    }

    return _config.captureUrl;
  }

  Future<void> _doCapture(String forPath,
      [Map<String, dynamic>? requestParams]) async {
    final spaUrl = _spaUrlFor(forPath, params: requestParams);
    _logger.i('$_logTag: capture via SPA: $spaUrl');

    final lang = requestParams?['language']?.toString();
    String script = '';
    int postDelay = 0;
    if (lang != null && lang != 'en' && _langButtonText.containsKey(lang)) {
      final target = _langButtonText[lang]!;
      script += '(function(){'
          'function clickBtn(el){if(!el)return false;'
          '["mousedown","mouseup","click"].forEach(function(t){el.dispatchEvent(new MouseEvent(t,{bubbles:true,cancelable:true}))});'
          'return true}'
          'var b=document.querySelectorAll("button");var lb=null;'
          'for(var i=0;i<b.length;i++){if(b[i].textContent.indexOf("Lang")>-1){lb=b[i];break;}}'
          'if(!lb)return "no_lang_btn";'
          'clickBtn(lb);'
          'setTimeout(function(){'
          'var c=document.querySelectorAll("button");var tb=null;'
          'for(var j=0;j<c.length;j++){if(c[j].textContent.indexOf("$target")>-1){tb=c[j];break;}}'
          'if(!tb)return;'
          'clickBtn(tb);'
          '},1000);'
          'return "ok";'
          '})()';
      postDelay = 6000;
      _logger.i('$_logTag: language script for $lang ($target)');
    }

    final nativeResult = await KuronNative.instance.headlessGetClearance(
      url: spaUrl,
      script: script,
      timeoutMs: _config.captureTimeoutMs,
      captureDelayMs: 4000,
      postScriptDelayMs: postDelay,
      captureUrlPattern: 'vrf=',
    );

    if (nativeResult == null || nativeResult == 'null') {
      _logger.w('$_logTag: capture returned null');
      return;
    }

    try {
      final map = json.decode(nativeResult) as Map<String, dynamic>;
      final urls = map['capturedUrls'] as List<dynamic>?;
      if (urls == null || urls.isEmpty) {
        _logger.w('$_logTag: no captured URLs');
        return;
      }

      int count = 0;
      for (final urlStr in urls.cast<String>()) {
        try {
          final u = Uri.parse(urlStr);
          final vrf = u.queryParameters[_config.vrfParam];
          if (vrf == null || vrf.isEmpty) continue;
          _cache.set(u.path, urlStr);
          count++;
        } catch (_) {}
      }
      _logger.i('$_logTag: stored $count VRF entries');
    } catch (e) {
      _logger.e('$_logTag: parse error', error: e);
    }
  }
}
