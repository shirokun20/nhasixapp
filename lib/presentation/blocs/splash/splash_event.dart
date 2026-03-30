part of 'splash_bloc.dart';

abstract class SplashEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SplashStartedEvent extends SplashEvent {}

class SplashCFBypassEvent extends SplashEvent {
  final String status;
  SplashCFBypassEvent({required this.status});

  @override
  List<Object?> get props => [status];
}

class SplashRetryBypassEvent extends SplashEvent {}

class SplashInitializeBypassEvent extends SplashEvent {}

class SplashOfflineModeEvent extends SplashEvent {}

/// Event to force continue in offline mode even without content
/// Allows user to access limited app features when no offline content exists
class SplashForceOfflineModeEvent extends SplashEvent {}

/// Event to manually check for offline content availability
/// Triggered when user wants to refresh offline content status
class SplashCheckOfflineContentEvent extends SplashEvent {}
