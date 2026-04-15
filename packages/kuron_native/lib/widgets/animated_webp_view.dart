import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../kuron_native.dart';

/// Native Android animated-WebP viewer backed by [AnimatedImageDrawable].
///
/// ## Thumbnail-first approach
/// Instead of immediately creating a [PlatformView] (which starts decoding all
/// animation frames), this widget first requests a lightweight JPEG thumbnail
/// (first frame only) from the native side. The list stays at full 60 fps with
/// zero animation overhead. Playback starts automatically when the page becomes
/// the active/visible reader page.
///
/// ## API levels
/// | API | Behaviour |
/// |-----|-----------|
/// | ≥ 28 | Full animated playback via `AnimatedImageDrawable` when visible |
/// | < 28 | Static first-frame via `BitmapFactory` |
/// | Non-Android | [fallback] widget is shown |
///
/// ## Usage
/// ```dart
/// if (AnimatedWebPView.isAvailable)
///   AnimatedWebPView(url: url, fallback: spinner)
/// ```
class AnimatedWebPView extends StatefulWidget {
  const AnimatedWebPView({
    super.key,
    required this.url,
    this.filePath,
    this.headers = const {},
    this.targetWidth,
    this.autoPlay = false,
    this.pageNumber,
    this.visiblePageNotifier,
    this.loadingBuilder,
    required this.fallback,
  });

  final String url;

  /// Absolute path to the already-downloaded file on disk.
  final String? filePath;

  /// Optional HTTP headers forwarded to the native downloader.
  final Map<String, String> headers;

  /// Target decode width in physical pixels.
  final int? targetWidth;

  /// When true, skip the thumbnail step and start animation immediately.
  /// In reader usage this is combined with [visiblePageNotifier] so only the
  /// current page auto-plays.
  final bool autoPlay;

  /// 1-based page number of this image in the reader.
  final int? pageNumber;

  /// Notifier that emits the currently visible page number.
  /// When provided, animation auto-pauses when this page is not visible.
  final ValueNotifier<int>? visiblePageNotifier;

  /// Optional builder for showing byte-level native preload progress.
  final Widget Function(
    BuildContext context,
    int receivedBytes,
    int? totalBytes,
  )?
  loadingBuilder;

  /// Widget shown while the thumbnail is loading or on non-Android platforms.
  final Widget fallback;

  /// Whether [AnimatedWebPView] can render on the current platform.
  static bool get isAvailable => Platform.isAndroid;

  @override
  State<AnimatedWebPView> createState() => _AnimatedWebPViewState();
}

class _AnimatedWebPViewState extends State<AnimatedWebPView>
    with WidgetsBindingObserver {
  /// Path to the cached JPEG thumbnail (first frame of the WebP).
  String? _thumbnailPath;

  /// When true, the [AndroidView] is mounted and animation plays.
  bool _isPlaying = false;

  /// Path to the raw WebP file cached on disk by [getThumbnailForWebP].
  /// Passed to [AnimatedWebPView] as `filePath` so first play loads from disk
  /// instantly — without a second network download.
  String? _webpCachePath;
  bool _isLoadingThumbnail = false;
  int _thumbnailDownloadedBytes = 0;
  int? _thumbnailTotalBytes;

  bool get _isCurrentVisiblePage {
    final notifier = widget.visiblePageNotifier;
    final pageNumber = widget.pageNumber;
    if (notifier == null || pageNumber == null) {
      return false;
    }
    return notifier.value == pageNumber;
  }

  bool get _shouldAutoPlay => widget.autoPlay || _isCurrentVisiblePage;

  bool get _hasPreparedPlaybackSource =>
      _webpCachePath != null ||
      widget.filePath != null ||
      _thumbnailPath != null;

  int? _resolveExistingFileBytes() {
    for (final candidatePath in <String?>[widget.filePath, _webpCachePath]) {
      if (candidatePath == null || candidatePath.isEmpty) {
        continue;
      }

      try {
        final file = File(candidatePath);
        if (!file.existsSync()) {
          continue;
        }

        final fileLength = file.lengthSync();
        if (fileLength > 0) {
          return fileLength;
        }
      } catch (_) {
        // Ignore file stat failures and fall back to live progress events.
      }
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.visiblePageNotifier?.addListener(_onVisiblePageChanged);
    _loadThumbnail();
  }

  @override
  void dispose() {
    widget.visiblePageNotifier?.removeListener(_onVisiblePageChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Auto-pause when this page is no longer the visible page.
  void _onVisiblePageChanged() {
    if (_shouldAutoPlay) {
      if (!_isPlaying && _hasPreparedPlaybackSource && mounted) {
        setState(() => _isPlaying = true);
      } else if (!_isPlaying && !_isLoadingThumbnail) {
        _loadThumbnail();
      }
      return;
    }

    if (_isPlaying && mounted) {
      setState(() => _isPlaying = false);
      if (_thumbnailPath == null) _loadThumbnail();
    }
  }

  /// When app goes to background or becomes inactive, tear down the
  /// [AndroidView] so the native [AnimatedImageDrawable] stops consuming
  /// CPU/GPU. On resume the current visible page auto-plays again; other pages
  /// return to their passive thumbnail preview.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_isPlaying && mounted) {
        setState(() => _isPlaying = false);
        // Ensure thumbnail is ready for when user returns.
        if (_thumbnailPath == null) _loadThumbnail();
      }
      return;
    }

    if (state == AppLifecycleState.resumed &&
        _shouldAutoPlay &&
        !_isPlaying &&
        mounted) {
      if (_hasPreparedPlaybackSource) {
        setState(() => _isPlaying = true);
      } else if (!_isLoadingThumbnail) {
        _loadThumbnail();
      }
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedWebPView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visiblePageNotifier != widget.visiblePageNotifier) {
      oldWidget.visiblePageNotifier?.removeListener(_onVisiblePageChanged);
      widget.visiblePageNotifier?.addListener(_onVisiblePageChanged);
    }
    if (oldWidget.url != widget.url) {
      setState(() {
        _thumbnailPath = null;
        _webpCachePath = null;
        _isPlaying = false;
        _thumbnailDownloadedBytes = 0;
        _thumbnailTotalBytes = null;
        _isLoadingThumbnail = false;
      });
      _loadThumbnail();
      return;
    }

    if (oldWidget.filePath != widget.filePath && mounted) {
      final existingFileBytes = _resolveExistingFileBytes();
      if (existingFileBytes != null &&
          (_thumbnailDownloadedBytes != existingFileBytes ||
              _thumbnailTotalBytes != null)) {
        setState(() {
          _thumbnailDownloadedBytes = existingFileBytes;
          _thumbnailTotalBytes = null;
        });
      }
    }

    if (oldWidget.autoPlay != widget.autoPlay ||
        oldWidget.pageNumber != widget.pageNumber ||
        oldWidget.visiblePageNotifier != widget.visiblePageNotifier) {
      _onVisiblePageChanged();
    }
  }

  /// Asks the native plugin to generate/return the JPEG thumbnail.
  Future<void> _loadThumbnail() async {
    if (_isLoadingThumbnail) return;
    _isLoadingThumbnail = true;
    final existingFileBytes = _resolveExistingFileBytes();

    if (mounted) {
      setState(() {
        _thumbnailDownloadedBytes = existingFileBytes ?? 0;
        _thumbnailTotalBytes = null;
      });
    } else {
      _thumbnailDownloadedBytes = existingFileBytes ?? 0;
      _thumbnailTotalBytes = null;
    }

    try {
      final raw = await KuronNative.instance.getThumbnailForWebP(
        url: widget.url,
        filePath: widget.filePath,
        headers: widget.headers,
        onProgress: (receivedBytes, totalBytes) {
          if (!mounted) return;
          if (_thumbnailDownloadedBytes == receivedBytes &&
              _thumbnailTotalBytes == totalBytes) {
            return;
          }
          setState(() {
            _thumbnailDownloadedBytes = receivedBytes;
            _thumbnailTotalBytes = totalBytes;
          });
        },
      );
      if (mounted) {
        setState(() {
          _isLoadingThumbnail = false;
          if (raw is Map) {
            _thumbnailPath = raw['thumbnailPath'] as String?;
            _webpCachePath = raw['webpPath'] as String?;
            if (_thumbnailPath == null) {
              // Thumbnail decode failed but webp cached — go straight to play
              _isPlaying = true;
            }
          } else if (raw is String) {
            // Backward-compat: old native builds return plain String
            _thumbnailPath = raw;
          } else {
            // Thumbnail unavailable — fall back to native animation.
            _isPlaying = true;
          }

          if (_shouldAutoPlay &&
              (_webpCachePath != null ||
                  widget.filePath != null ||
                  _thumbnailPath != null)) {
            _isPlaying = true;
          }
        });
      }
    } catch (_) {
      // Native call failed — show animated view directly so user still sees content.
      if (mounted) {
        setState(() {
          _isLoadingThumbnail = false;
          _isPlaying = _shouldAutoPlay;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) return widget.fallback;

    // ── Playing: native animated view ──────────────────────────────────────
    if (_isPlaying) {
      return SizedBox.expand(
        child: AndroidView(
          viewType: 'kuron_animated_webp_view',
          layoutDirection: TextDirection.ltr,
          creationParams: <String, Object>{
            'url': widget.url,
            // Prefer webp cache written during thumbnail load (instant, no re-download).
            // Fall back to widget.filePath (extended_image disk cache) if available.
            if (_webpCachePath != null)
              'filePath': _webpCachePath!
            else if (widget.filePath != null)
              'filePath': widget.filePath!,
            'headers': widget.headers,
            if (widget.targetWidth != null) 'targetWidth': widget.targetWidth!,
          },
          creationParamsCodec: const StandardMessageCodec(),
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        ),
      );
    }

    // ── Thumbnail ready: passive preview until the page becomes visible ────
    if (_thumbnailPath != null) {
      return SizedBox.expand(
        child: Image.file(File(_thumbnailPath!), fit: BoxFit.contain),
      );
    }

    // ── Still loading thumbnail ─────────────────────────────────────────────
    return widget.loadingBuilder?.call(
          context,
          _thumbnailDownloadedBytes,
          _thumbnailTotalBytes,
        ) ??
        widget.fallback;
  }
}
