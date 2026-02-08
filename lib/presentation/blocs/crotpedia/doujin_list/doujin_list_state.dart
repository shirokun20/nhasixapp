import 'package:equatable/equatable.dart';
import 'package:nhasixapp/domain/entities/crotpedia/crotpedia_entities.dart';

abstract class DoujinListState extends Equatable {
  const DoujinListState();

  @override
  List<Object> get props => [];
}

class DoujinListInitial extends DoujinListState {}

class DoujinListLoading extends DoujinListState {}

class DoujinListLoaded extends DoujinListState {
  final List<DoujinListItem> doujins;

  const DoujinListLoaded(this.doujins);

  @override
  List<Object> get props => [doujins];
}

class DoujinListError extends DoujinListState {
  final String message;

  const DoujinListError(this.message);

  @override
  List<Object> get props => [message];
}
