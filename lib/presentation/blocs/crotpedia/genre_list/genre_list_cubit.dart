import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/domain/repositories/crotpedia/crotpedia_feature_repository.dart';
import 'genre_list_state.dart';

class GenreListCubit extends Cubit<GenreListState> {
  final CrotpediaFeatureRepository _repository;

  GenreListCubit(this._repository) : super(GenreListInitial());

  Future<void> fetchGenres() async {
    emit(GenreListLoading());
    try {
      final genres = await _repository.getGenreList();
      if (genres.isEmpty) {
        emit(const GenreListError('No genres found'));
      } else {
        emit(GenreListLoaded(genres));
      }
    } catch (e) {
      emit(GenreListError(e.toString()));
    }
  }

  Future<void> refreshGenres() async {
    // Optionally handle force refresh if repository supports it, but for genre list usually fine to just refetch
    fetchGenres();
  }
}
