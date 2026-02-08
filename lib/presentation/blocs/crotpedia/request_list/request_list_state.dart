import 'package:equatable/equatable.dart';
import 'package:nhasixapp/domain/entities/crotpedia/crotpedia_entities.dart';

abstract class RequestListState extends Equatable {
  const RequestListState();

  @override
  List<Object> get props => [];
}

class RequestListInitial extends RequestListState {}

class RequestListLoading extends RequestListState {}

class RequestListLoaded extends RequestListState {
  final List<RequestItem> requests;
  final bool hasNext;
  final int page;
  final bool isLoadingMore;

  const RequestListLoaded({
    required this.requests,
    this.hasNext = true,
    this.page = 1,
    this.isLoadingMore = false,
  });

  RequestListLoaded copyWith({
    List<RequestItem>? requests,
    bool? hasNext,
    int? page,
    bool? isLoadingMore,
  }) {
    return RequestListLoaded(
      requests: requests ?? this.requests,
      hasNext: hasNext ?? this.hasNext,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object> get props => [requests, hasNext, page, isLoadingMore];
}

class RequestListError extends RequestListState {
  final String message;

  const RequestListError(this.message);

  @override
  List<Object> get props => [message];
}
