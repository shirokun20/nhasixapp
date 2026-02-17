part of 'genre_list_cubit.dart';

abstract class GenreListState extends BaseCubitState {
  const GenreListState();
}

class GenreListInitial extends GenreListState {
  const GenreListInitial();

  @override
  List<Object?> get props => [];
}

class GenreListLoading extends GenreListState {
  const GenreListLoading();

  @override
  List<Object?> get props => [];
}

class GenreListLoaded extends GenreListState {
  final List<Genre> genres;

  const GenreListLoaded({required this.genres});

  @override
  List<Object?> get props => [genres];
}

class GenreListError extends GenreListState {
  final String message;

  const GenreListError(this.message);

  @override
  List<Object?> get props => [message];
}
