import '../../../core/di/service_locator.dart';
import '../../../domain/usecases/tags/get_tag_detail_usecase.dart';
import '../base/base_cubit.dart';
import 'tag_detail_state.dart';

class TagDetailCubit extends BaseCubit<TagDetailState> {
  TagDetailCubit({
    required super.logger,
  }) : super(initialState: const TagDetailInitial());

  Future<void> loadTagDetail({
    required String tagType,
    required String slug,
    required String sourceId,
  }) async {
    emit(const TagDetailLoading());
    try {
      final useCase = getIt<GetTagDetailUseCase>();
      final tagDetail = await useCase(GetTagDetailParams(
        tagType: tagType,
        slug: slug,
        sourceId: sourceId,
      ));
      emit(TagDetailLoaded(tagDetail));
    } catch (e, stackTrace) {
      logger.e('Error loading tag detail', error: e, stackTrace: stackTrace);
      emit(TagDetailError(e.toString()));
    }
  }
}
