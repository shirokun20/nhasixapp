import '../../../domain/entities/tags/tag_detail_entity.dart';
import '../base/base_cubit.dart';

sealed class TagDetailState extends BaseCubitState {
  const TagDetailState();

  @override
  List<Object?> get props => [];
}

class TagDetailInitial extends TagDetailState {
  const TagDetailInitial();
}

class TagDetailLoading extends TagDetailState {
  const TagDetailLoading();
}

class TagDetailLoaded extends TagDetailState {
  const TagDetailLoaded(this.tagDetail);

  final TagDetailEntity tagDetail;

  @override
  List<Object?> get props => [tagDetail];
}

class TagDetailError extends TagDetailState {
  const TagDetailError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
