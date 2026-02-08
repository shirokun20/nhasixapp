import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/domain/repositories/crotpedia/crotpedia_feature_repository.dart';
import 'doujin_list_state.dart';

class DoujinListCubit extends Cubit<DoujinListState> {
  final CrotpediaFeatureRepository _repository;
  bool _hasCachedData = false;

  DoujinListCubit(this._repository) : super(DoujinListInitial());

  Future<void> fetchDoujins({bool forceRefresh = false}) async {
    try {
      // For force refresh, always show syncing
      if (forceRefresh) {
        emit(const DoujinListSyncing('Syncing with server...'));
      } else {
        // For initial load, show syncing because cache is likely empty
        if (!_hasCachedData) {
          emit(const DoujinListSyncing('Downloading doujin list...\nThis may take a moment on first use.'));
        } else {
          emit(DoujinListLoading());
        }
      }
      
      final doujins = await _repository.getDoujinList(forceRefresh: forceRefresh);
      
      if (doujins.isNotEmpty) {
        _hasCachedData = true;
      }
      
      if (doujins.isEmpty) {
        emit(const DoujinListError('No doujins found'));
      } else {
        emit(DoujinListLoaded(doujins));
      }
    } catch (e) {
      emit(DoujinListError(e.toString()));
    }
  }
}
