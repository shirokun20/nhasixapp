part of 'splash_bloc.dart';

abstract class SplashState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SplashInitial extends SplashState {}

class SplashInitializing extends SplashState {
  final String message;
  final double progress;
  SplashInitializing({
    this.message = 'Initializing...',
    this.progress = 0.0,
  });
  @override
  List<Object?> get props => [message, progress];
}

class SplashCloudflareInitial extends SplashState {}

class SplashBypassInProgress extends SplashState {
  final String message;

  SplashBypassInProgress({this.message = 'Bypassing Cloudflare protection...'});

  @override
  List<Object?> get props => [message];
}

class SplashSuccess extends SplashState {
  final String message;

  SplashSuccess({this.message = 'Successfully bypassed Cloudflare protection'});

  @override
  List<Object?> get props => [message];
}

class SplashOfflineSuccess extends SplashState {
  final String message;
  final int downloadCount;

  SplashOfflineSuccess({
    required this.downloadCount,
    String? message,
  }) : message = message ??
            'Offline mode: $downloadCount downloaded contents available';

  @override
  List<Object?> get props => [message, downloadCount];
}

class SplashError extends SplashState {
  final String message;
  final bool canRetry;
  final bool canUseOffline;

  SplashError({
    required this.message,
    this.canRetry = true,
    this.canUseOffline = false,
  });

  @override
  List<Object?> get props => [message, canRetry, canUseOffline];
}

/// State when offline mode is detected
/// Shows message while checking for offline content availability
class SplashOfflineDetected extends SplashState {
  final String message;

  SplashOfflineDetected({
    this.message = 'No internet connection. Checking offline content...',
  });

  @override
  List<Object?> get props => [message];
}

/// State when offline content is available
/// Shows count of available offline items before auto-continuing
class SplashOfflineReady extends SplashState {
  final String message;
  final int offlineContentCount;

  SplashOfflineReady({
    required this.offlineContentCount,
    String? message,
  }) : message = message ??
            'Found $offlineContentCount offline items. Continuing...';

  @override
  List<Object?> get props => [message, offlineContentCount];
}

/// State when no offline content is available
/// Shows options for user to retry, continue anyway, or exit
class SplashOfflineEmpty extends SplashState {
  final String message;

  SplashOfflineEmpty({
    this.message = 'No internet connection and no offline content available.',
  });

  @override
  List<Object?> get props => [message];
}

/// State when app is running in offline mode
/// Indicates limited functionality but allows app usage
class SplashOfflineMode extends SplashState {
  final String message;
  final bool canRetryOnline;

  SplashOfflineMode({
    this.message = 'Offline Mode (Limited Features)',
    this.canRetryOnline = true,
  });

  @override
  List<Object?> get props => [message, canRetryOnline];
}
