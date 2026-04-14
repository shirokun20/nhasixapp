import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Native Android animated-WebP viewer backed by [AnimatedImageDrawable].
///
/// ## Thumbnail-first approach
/// Instead of immediately creating a [PlatformView] (which starts decoding all
/// animation frames), this widget first requests a lightweight JPEG thumbnail
/// (first frame only) from the native side. The list stays at full 60 fps with
/// zero animation overhead. The full animation starts only when the user taps.
///
/// ## API levels
/// | API | Behaviour |
/// |-----|-----------|
/// | ≥ 28 | Full animated playback via `AnimatedImageDrawable` on tap |
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
  final bool autoPlay;

  /// 1-based page number of this image in the reader.
  final int? pageNumber;

  /// Notifier that emits the currently visible page number.
  /// When provided, animation auto-pauses when this page is not visible.
  final ValueNotifier<int>? visiblePageNotifier;

  /// Widget shown while the thumbnail is loading or on non-Android platforms.
  final Widget fallback;

  /// Whether [AnimatedWebPView] can render on the current platform.
  static bool get isAvailable => Platform.isAndroid;

  @override
  State<AnimatedWebPView> createState() => _AnimatedWebPViewState();
}

class _AnimatedWebPViewState extends State<AnimatedWebPView>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('kuron_native');

  /// Path to the cached JPEG thumbnail (first frame of the WebP).
  String? _thumbnailPath;

  /// When true, the [AndroidView] is mounted and animation plays.
  bool _isPlaying = false;

  /// Path to the raw WebP file cached on disk by [getThumbnailForWebP].
  /// Passed to [AnimatedWebPView] as `filePath` so first play loads from disk
  /// instantly — without a second network download.
  String? _webpCachePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.visiblePageNotifier?.addListener(_onVisiblePageChanged);
    if (widget.autoPlay) {
      _isPlaying = true;
    } else {
      _loadThumbnail();
    }
  }

  @override
  void dispose() {
    widget.visiblePageNotifier?.removeListener(_onVisiblePageChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Auto-pause when this page is no longer the visible page.
  void _onVisiblePageChanged() {
    final notifier = widget.visiblePageNotifier;
    if (notifier == null || widget.pageNumber == null) return;
    if (_isPlaying && notifier.value != widget.pageNumber && mounted) {
      setState(() => _isPlaying = false);
      if (_thumbnailPath == null) _loadThumbnail();
    }
  }

  /// When app goes to background or becomes inactive, tear down the
  /// [AndroidView] so the native [AnimatedImageDrawable] stops consuming
  /// CPU/GPU. On resume the user sees the thumbnail + play button.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_isPlaying && mounted) {
        setState(() => _isPlaying = false);
        // Ensure thumbnail is ready for when user returns.
        if (_thumbnailPath == null) _loadThumbnail();
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
      if (widget.autoPlay) {
        setState(() {
          _thumbnailPath = null;
          _webpCachePath = null;
          _isPlaying = true;
        });
      } else {
        setState(() {
          _thumbnailPath = null;
          _webpCachePath = null;
          _isPlaying = false;
        });
        _loadThumbnail();
      }
    }
  }

  /// Asks the native plugin to generate/return the JPEG thumbnail.
  Future<void> _loadThumbnail() async {
    try {
      final raw = await _channel.invokeMethod<Object>(
        'getThumbnailForWebP',
        <String, Object?>{
          'url': widget.url,
          if (widget.filePath != null) 'filePath': widget.filePath!,
        },
      );
      if (mounted) {
        setState(() {
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
        });
      }
    } catch (_) {
      // Native call failed — show animated view directly so user still sees content.
      if (mounted) setState(() => _isPlaying = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) return widget.fallback;

    // ── Playing: native animated view — double-tap anywhere to pause ─────
    if (_isPlaying) {
      return GestureDetector(
        onDoubleTap: () {
          setState(() => _isPlaying = false);
          if (_thumbnailPath == null) _loadThumbnail();
        },
        child: SizedBox.expand(
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
              if (widget.targetWidth != null)
                'targetWidth': widget.targetWidth!,
            },
            creationParamsCodec: const StandardMessageCodec(),
            // Don't let AndroidView absorb touches — animation needs no user input.
            // This allows the GestureDetector parent to receive double-taps.
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          ),
        ),
      );
    }

    // ── Thumbnail ready: static preview + play button ───────────────────────
    if (_thumbnailPath != null) {
      return GestureDetector(
        onTap: () => setState(() => _isPlaying = true),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: Image.file(File(_thumbnailPath!), fit: BoxFit.contain),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
          ],
        ),
      );
    }

    // ── Still loading thumbnail ─────────────────────────────────────────────
    return widget.fallback;
  }
}
