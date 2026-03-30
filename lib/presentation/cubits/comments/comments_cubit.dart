import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/domain/usecases/content/get_comments_usecase.dart';
import 'comments_state.dart';

class CommentsCubit extends Cubit<CommentsState> {
  final GetCommentsUseCase _getCommentsUseCase;

  CommentsCubit(this._getCommentsUseCase) : super(CommentsInitial());

  Future<void> loadComments(String contentId) async {
    emit(CommentsLoading());

    try {
      final comments = await _getCommentsUseCase(contentId);

      if (comments.isEmpty) {
        emit(CommentsEmpty());
      } else {
        emit(CommentsLoaded(comments));
      }
    } catch (e) {
      emit(CommentsError(e.toString()));
    }
  }
}
