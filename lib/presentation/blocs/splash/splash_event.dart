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
