import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/domain/repositories/crotpedia/crotpedia_feature_repository.dart';
import 'request_list_state.dart';

class RequestListCubit extends Cubit<RequestListState> {
  final CrotpediaFeatureRepository _repository;

  RequestListCubit(this._repository) : super(RequestListInitial());

  Future<void> loadFirstPage() async {
    emit(RequestListLoading());
    try {
      final requests = await _repository.getRequestList(page: 1);
      if (requests.isEmpty) {
        emit(const RequestListError('No requests found'));
      } else {
        emit(RequestListLoaded(
          requests: requests,
          hasNext: requests.isNotEmpty, // Assuming if empty, no more
          page: 1,
        ));
      }
    } catch (e) {
      emit(RequestListError(e.toString()));
    }
  }

  Future<void> loadNextPage() async {
    if (state is RequestListLoaded) {
      final currentState = state as RequestListLoaded;
      if (currentState.isLoadingMore || !currentState.hasNext) return;

      emit(currentState.copyWith(isLoadingMore: true));

      try {
        final nextPage = currentState.page + 1;
        final newRequests = await _repository.getRequestList(page: nextPage);
        
        if (newRequests.isEmpty) {
          emit(currentState.copyWith(
            hasNext: false,
            isLoadingMore: false,
          ));
        } else {
          emit(currentState.copyWith(
            requests: [...currentState.requests, ...newRequests],
            page: nextPage,
            isLoadingMore: false,
            hasNext: true, // Assuming if we got data, there might be more. Ideally pagination info should be returned.
          ));
        }
      } catch (e) {
        // Keep existing list on error, just stop loading more
        emit(currentState.copyWith(isLoadingMore: false));
        // Optionally emit a side effect or show error via separate mechanism, but here we keep state.
      }
    }
  }
}
