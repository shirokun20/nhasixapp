part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class HomeStartedEvent extends HomeEvent {}

class HomeRefreshEvent extends HomeEvent {}
