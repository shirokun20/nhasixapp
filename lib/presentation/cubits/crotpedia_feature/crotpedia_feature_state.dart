import 'package:equatable/equatable.dart';
import '../../../../domain/entities/crotpedia/crotpedia_entities.dart';

abstract class CrotpediaFeatureState extends Equatable {
  const CrotpediaFeatureState();

  @override
  List<Object?> get props => [];
}

class CrotpediaFeatureInitial extends CrotpediaFeatureState {}

class CrotpediaFeatureLoading extends CrotpediaFeatureState {}

class CrotpediaFeatureSyncing extends CrotpediaFeatureState {
  final String message;
  const CrotpediaFeatureSyncing(this.message);
  @override
  List<Object?> get props => [message];
}

class GenreListLoaded extends CrotpediaFeatureState {
  final List<GenreItem> genres;

  const GenreListLoaded(this.genres);

  @override
  List<Object?> get props => [genres];
}

class DoujinListLoaded extends CrotpediaFeatureState {
  final List<DoujinListItem> doujins;
  final bool isRefreshing;

  const DoujinListLoaded(this.doujins, {this.isRefreshing = false});

  @override
  List<Object?> get props => [doujins, isRefreshing];
}

class RequestListLoaded extends CrotpediaFeatureState {
  final List<RequestItem> requests;
  final int page;
  final bool hasNext;
  final bool isLoadingMore;

  const RequestListLoaded(
    this.requests, {
    this.page = 1,
    this.hasNext = false,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [requests, page, hasNext, isLoadingMore];
}

class CrotpediaFeatureError extends CrotpediaFeatureState {
  final String message;

  const CrotpediaFeatureError(this.message);

  @override
  List<Object?> get props => [message];
}
