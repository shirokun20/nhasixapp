import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';
import '../../../core/di/service_locator.dart';
import '../../../services/download_service.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial()) {
    on<HomeStartedEvent>(_onHomeStarted);
  }

  Future<void> _onHomeStarted(
    HomeStartedEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());
    
    // 🔒 PRIVACY: Ensure existing downloads have .nomedia protection in background
    _ensureDownloadPrivacy();
    
    await Future.delayed(const Duration(seconds: 2));
    emit(HomeLoaded(data: "Initial Data"));
  }
  
  /// Ensure download privacy protection in background
  void _ensureDownloadPrivacy() {
    try {
      final downloadService = getIt<DownloadService>();
      downloadService.ensurePrivacyProtection().catchError((e) {
        Logger().w('HomeBloc: Failed to ensure download privacy: $e');
      });
    } catch (e) {
      Logger().w('HomeBloc: Error accessing download service for privacy: $e');
    }
  }
}
