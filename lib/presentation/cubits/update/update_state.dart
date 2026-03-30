import 'package:equatable/equatable.dart';
import '../../../../core/services/update_service.dart';

abstract class UpdateState extends Equatable {
  const UpdateState();

  @override
  List<Object?> get props => [];
}

class UpdateInitial extends UpdateState {}

class UpdateChecking extends UpdateState {}

class UpdateAvailable extends UpdateState {
  final UpdateInfo updateInfo;

  const UpdateAvailable(this.updateInfo);

  @override
  List<Object?> get props => [updateInfo];
}

class UpdateNotAvailable extends UpdateState {
  // Flag to indicate if this result came from a manual check
  final bool isManualCheck;

  const UpdateNotAvailable({this.isManualCheck = false});

  @override
  List<Object?> get props => [isManualCheck];
}

class UpdateError extends UpdateState {
  final String message;
  final bool isManualCheck;

  const UpdateError(this.message, {this.isManualCheck = false});

  @override
  List<Object?> get props => [message, isManualCheck];
}
