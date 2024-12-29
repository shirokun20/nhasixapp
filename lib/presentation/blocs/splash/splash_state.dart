part of 'splash_bloc.dart';

abstract class SplashState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SplashInitial extends SplashState {}

class SplashSuccess extends SplashState {}

class SplashError extends SplashState {
  final String message;
  SplashError({required this.message});
}

class SplashCloudflareInitial extends SplashState {}
