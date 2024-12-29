part of 'splash_bloc.dart';

abstract class SplashState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SplashInitial extends SplashState {}

class SplashSuccess extends SplashState {}

class SplashCloudflareInitial extends SplashState {}
