part of 'content_list_cubit.dart';

abstract class ContentListState extends BaseCubitState {
  const ContentListState();
}

class ContentListInitial extends ContentListState {
  const ContentListInitial();

  @override
  List<Object?> get props => [];
}

class ContentListLoading extends ContentListState {
  const ContentListLoading();

  @override
  List<Object?> get props => [];
}

class ContentListLoaded extends ContentListState {
  final List<Content> items;
  final int currentPage;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;
  final String? currentFilter;

  const ContentListLoaded({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
    this.currentFilter,
  });

  @override
  List<Object?> get props => [
        items,
        currentPage,
        totalPages,
        hasNext,
        hasPrevious,
        currentFilter,
      ];
}

class ContentListError extends ContentListState {
  final String message;

  const ContentListError(this.message);

  @override
  List<Object?> get props => [message];
}
