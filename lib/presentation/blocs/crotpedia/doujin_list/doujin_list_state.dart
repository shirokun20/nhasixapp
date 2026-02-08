import 'package:equatable/equatable.dart';
import 'package:nhasixapp/domain/entities/crotpedia/crotpedia_entities.dart';

abstract class DoujinListState extends Equatable {
  const DoujinListState();

  @override
  List<Object> get props => [];
}

class DoujinListInitial extends DoujinListState {}

class DoujinListLoading extends DoujinListState {}

// New state for when syncing from network
class DoujinListSyncing extends DoujinListState {
  final String message;

  const DoujinListSyncing(this.message);

  @override
  List<Object> get props => [message];
}

class DoujinListLoaded extends DoujinListState {
  final List<DoujinListItem> doujins;
  final bool isSyncing; // True when syncing in background

  const DoujinListLoaded(this.doujins, {this.isSyncing = false});

  @override
  List<Object> get props => [doujins, isSyncing];
}

class DoujinListError extends DoujinListState {
  final String message;

  const DoujinListError(this.message);

  @override
  List<Object> get props => [message];
}
