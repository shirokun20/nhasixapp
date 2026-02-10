import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../../../../domain/usecases/crotpedia/get_genre_list_usecase.dart';
import '../../../../domain/usecases/crotpedia/get_doujin_list_usecase.dart';
import '../../../../domain/usecases/crotpedia/get_request_list_usecase.dart';
import 'crotpedia_feature_state.dart';

class CrotpediaFeatureCubit extends Cubit<CrotpediaFeatureState> {
  final GetGenreListUseCase getGenreListUseCase;
  final GetDoujinListUseCase getDoujinListUseCase;
  final GetRequestListUseCase getRequestListUseCase;
  final Logger logger;

  CrotpediaFeatureCubit({
    required this.getGenreListUseCase,
    required this.getDoujinListUseCase,
    required this.getRequestListUseCase,
    required this.logger,
  }) : super(CrotpediaFeatureInitial());

  Future<void> loadGenreList() async {
    try {
      emit(CrotpediaFeatureLoading());
      final genres = await getGenreListUseCase();
      emit(GenreListLoaded(genres));
    } catch (e) {
      logger.e('Failed to load genre list', error: e);
      emit(CrotpediaFeatureError(e.toString()));
    }
  }

  Future<void> loadDoujinList({bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        emit(const CrotpediaFeatureSyncing('Syncing with server...'));
      } else {
        emit(CrotpediaFeatureLoading());
      }

      final doujins = await getDoujinListUseCase(forceRefresh: forceRefresh);
      emit(DoujinListLoaded(doujins));
    } catch (e) {
      logger.e('Failed to load doujin list', error: e);
      emit(CrotpediaFeatureError(e.toString()));
    }
  }

  Future<void> loadRequestList({int page = 1}) async {
    try {
      if (page == 1) {
        emit(CrotpediaFeatureLoading());
      } else {
        if (state is RequestListLoaded) {
          final currentState = state as RequestListLoaded;
          // Emit loading more state to show spinner at bottom
          emit(RequestListLoaded(
            currentState.requests,
            page: currentState.page,
            hasNext: currentState.hasNext,
            isLoadingMore: true,
          ));
        }
      }

      final requests = await getRequestListUseCase(page: page);

      // Determine if there's a next page (simple heuristic if full page returned)
      // Ideally repository/usecase should return pagination info
      final hasNext = requests.isNotEmpty; // Simple assumption

      if (state is RequestListLoaded && page > 1) {
        final currentRequests = (state as RequestListLoaded).requests;
        emit(RequestListLoaded(
          [...currentRequests, ...requests],
          page: page,
          hasNext: hasNext,
          isLoadingMore: false,
        ));
      } else {
        emit(RequestListLoaded(
          requests,
          page: page,
          hasNext: hasNext,
          isLoadingMore: false,
        ));
      }
    } catch (e) {
      logger.e('Failed to load request list', error: e);
      if (page == 1) {
        emit(CrotpediaFeatureError(e.toString()));
      } else {
        // If pagination fails, revert loading state
        if (state is RequestListLoaded) {
          final currentState = state as RequestListLoaded;
          emit(RequestListLoaded(
            currentState.requests,
            page: currentState.page,
            hasNext: currentState.hasNext,
            isLoadingMore: false,
          ));
        }
      }
    }
  }

  Future<void> loadNextRequestPage() async {
    if (state is RequestListLoaded) {
      final currentState = state as RequestListLoaded;
      if (currentState.isLoadingMore || !currentState.hasNext) return;

      await loadRequestList(page: currentState.page + 1);
    }
  }
}
