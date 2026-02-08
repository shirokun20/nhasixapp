import 'package:equatable/equatable.dart';
import 'package:nhasixapp/domain/entities/crotpedia/crotpedia_entities.dart';

abstract class GenreListState extends Equatable {
  const GenreListState();

  @override
  List<Object> get props => [];
}

class GenreListInitial extends GenreListState {}

class GenreListLoading extends GenreListState {}

class GenreListLoaded extends GenreListState {
  final List<GenreItem> genres;

  const GenreListLoaded(this.genres);

  @override
  List<Object> get props => [genres];
}

class GenreListError extends GenreListState {
  final String message;

  const GenreListError(this.message);

  @override
  List<Object> get props => [message];
}
