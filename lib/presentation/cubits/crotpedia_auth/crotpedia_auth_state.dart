part of 'crotpedia_auth_cubit.dart';

abstract class CrotpediaAuthState extends Equatable {
  const CrotpediaAuthState();

  @override
  List<Object?> get props => [];
}

class CrotpediaAuthInitial extends CrotpediaAuthState {}

class CrotpediaAuthLoading extends CrotpediaAuthState {}

class CrotpediaAuthSuccess extends CrotpediaAuthState {
  final String username;

  const CrotpediaAuthSuccess(this.username);

  @override
  List<Object?> get props => [username];
}

class CrotpediaAuthError extends CrotpediaAuthState {
  final String message;

  const CrotpediaAuthError(this.message);

  @override
  List<Object?> get props => [message];
}
