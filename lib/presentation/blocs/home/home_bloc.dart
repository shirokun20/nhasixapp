import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

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
    await Future.delayed(const Duration(seconds: 2));
    emit(HomeLoaded(data: "Initial Data"));
  }
}
