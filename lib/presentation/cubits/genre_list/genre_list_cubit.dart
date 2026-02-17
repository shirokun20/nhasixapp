import '../../../domain/entities/entities.dart';
import '../../../domain/usecases/content/get_genre_list_usecase.dart';
import '../base/base_cubit.dart';

part 'genre_list_state.dart';

/// Cubit for managing genre list state (no pagination)
class GenreListCubit extends BaseCubit<GenreListState> {
  final GetGenreListUseCase _getGenreListUseCase;
  final String sourceId;

  GenreListCubit({
    required GetGenreListUseCase getGenreListUseCase,
    required this.sourceId,
    required super.logger,
  })  : _getGenreListUseCase = getGenreListUseCase,
        super(initialState: const GenreListInitial());

  /// Initialize and load genres
  Future<void> initialize() async {
    if (isClosed) return;

    emit(const GenreListLoading());

    try {
      final result = await _getGenreListUseCase(
        GetGenreListParams(sourceId: sourceId),
      );

      if (!isClosed) {
        emit(GenreListLoaded(genres: result));
      }
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'initialize');
      if (!isClosed) {
        emit(GenreListError(e.toString()));
      }
    }
  }

  /// Refresh genre list
  Future<void> refresh() async {
    await initialize();
  }
}
