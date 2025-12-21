import 'package:bloc/bloc.dart';
import 'package:logger/logger.dart';
import '../../../../core/services/update_service.dart';
import 'update_state.dart';

class UpdateCubit extends Cubit<UpdateState> {
  final UpdateService _updateService;
  final Logger _logger;

  UpdateCubit({
    required UpdateService updateService,
    required Logger logger,
  })  : _updateService = updateService,
        _logger = logger,
        super(UpdateInitial());

  Future<void> checkForUpdate({bool isManual = false}) async {
    if (state is UpdateChecking) return;

    try {
      emit(UpdateChecking());

      final updateInfo = await _updateService.checkForUpdate();

      if (updateInfo != null) {
        emit(UpdateAvailable(updateInfo));
      } else {
        emit(UpdateNotAvailable(isManualCheck: isManual));
      }
    } catch (e) {
      _logger.e('UpdateCubit: Error checking for update', error: e);
      emit(UpdateError(e.toString(), isManualCheck: isManual));
    }
  }
}
