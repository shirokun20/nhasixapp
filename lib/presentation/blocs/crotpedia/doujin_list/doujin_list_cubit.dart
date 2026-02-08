import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/domain/repositories/crotpedia/crotpedia_feature_repository.dart';
import 'doujin_list_state.dart';

class DoujinListCubit extends Cubit<DoujinListState> {
  final CrotpediaFeatureRepository _repository;

  DoujinListCubit(this._repository) : super(DoujinListInitial());

  Future<void> fetchDoujins({bool forceRefresh = false}) async {
    emit(DoujinListLoading());
    try {
      final doujins = await _repository.getDoujinList(forceRefresh: forceRefresh);
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
