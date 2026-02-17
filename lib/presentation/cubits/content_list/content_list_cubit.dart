import '../../../domain/entities/entities.dart';
import '../../../domain/usecases/content/get_content_list_by_type_usecase.dart';
import '../base/base_cubit.dart';

part 'content_list_state.dart';

/// Cubit for managing content list state
/// Handles: Manga, Manhua, Manhwa, A-Z, Project lists
class ContentListCubit extends BaseCubit<ContentListState> {
  final GetContentListByTypeUseCase _getContentListByTypeUseCase;
  final ContentListType listType;
  final String sourceId;

  ContentListCubit({
    required GetContentListByTypeUseCase getContentListByTypeUseCase,
    required this.listType,
    required this.sourceId,
    required super.logger,
  })  : _getContentListByTypeUseCase = getContentListByTypeUseCase,
        super(initialState: const ContentListInitial());

  /// Initialize and load first page
  Future<void> initialize({String? filter}) async {
    await loadPage(1, filter: filter);
  }

  /// Load specific page
  Future<void> loadPage(int page, {String? filter}) async {
    if (isClosed) return;

    emit(const ContentListLoading());

    try {
      final result = await _getContentListByTypeUseCase(
        GetContentListByTypeParams(
          sourceId: sourceId,
          listType: listType,
          page: page,
          filter: filter,
        ),
      );

      if (!isClosed) {
        emit(ContentListLoaded(
          items: result.contents,
          currentPage: result.currentPage,
          totalPages: result.totalPages,
          hasNext: result.hasNext,
          hasPrevious: result.hasPrevious,
          currentFilter: filter,
        ));
      }
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'loadPage');
      if (!isClosed) {
        emit(ContentListError(e.toString()));
      }
    }
  }

  /// Refresh current page
  Future<void> refresh() async {
    final currentState = state;
    if (currentState is ContentListLoaded) {
      await loadPage(
        currentState.currentPage,
        filter: currentState.currentFilter,
      );
    } else {
      await initialize();
    }
  }

  /// Go to next page
  Future<void> nextPage() async {
    final currentState = state;
    if (currentState is ContentListLoaded && currentState.hasNext) {
      await loadPage(
        currentState.currentPage + 1,
        filter: currentState.currentFilter,
      );
    }
  }

  /// Go to previous page
  Future<void> previousPage() async {
    final currentState = state;
    if (currentState is ContentListLoaded && currentState.hasPrevious) {
      await loadPage(
        currentState.currentPage - 1,
        filter: currentState.currentFilter,
      );
    }
  }

  /// Jump to specific page
  Future<void> goToPage(int page) async {
    final currentState = state;
    if (currentState is ContentListLoaded) {
      if (page >= 1 && page <= currentState.totalPages) {
        await loadPage(page, filter: currentState.currentFilter);
      }
    }
  }

  /// Change alphabet filter (A-Z list only)
  Future<void> changeFilter(String? filter) async {
    await loadPage(1, filter: filter);
  }
}
