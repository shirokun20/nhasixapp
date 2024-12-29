import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc() : super(SplashInitial()) {
    on<SplashStartedEvent>(_onSplashStarted);
    on<SplashCFBypassEvent>(_onByPassCloudflare);
  }

  Future<void> _onSplashStarted(
    SplashStartedEvent event,
    Emitter<SplashState> emit,
  ) async {
    emit(SplashCloudflareInitial());
  }

  Future<void> _onByPassCloudflare(
    SplashCFBypassEvent event,
    Emitter<SplashState> emit,
  ) async {
    if (event.status.contains("success")) {
      emit(SplashSuccess());
    } else {
      emit(SplashError(
          message: "failed to bypass cloudflare, please using dns or vpn."));
    }
  }
}
