part of 'splash_bloc.dart';

abstract class SplashState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SplashInitial extends SplashState {}

class SplashInitializing extends SplashState {}

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

class SplashError extends SplashState {
  final String message;
  final bool canRetry;

  SplashError({
    required this.message,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [message, canRetry];
}
