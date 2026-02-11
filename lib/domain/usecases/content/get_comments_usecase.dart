import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/domain/repositories/content_repository.dart';
import 'package:nhasixapp/domain/usecases/base_usecase.dart';

class GetCommentsUseCase extends UseCase<List<Comment>, String> {
  GetCommentsUseCase(this._repository);

  final ContentRepository _repository;

  @override
  Future<List<Comment>> call(String params) {
    return _repository.getComments(params);
  }
}
