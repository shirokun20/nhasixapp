import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kuron_crotpedia/kuron_crotpedia.dart';
import 'package:logger/logger.dart';

part 'crotpedia_auth_state.dart';

class CrotpediaAuthCubit extends Cubit<CrotpediaAuthState> {
  final CrotpediaAuthManager _authManager;
  final Logger _logger;

  CrotpediaAuthCubit({
    required CrotpediaAuthManager authManager,
    required Logger logger,
  })  : _authManager = authManager,
        _logger = logger,
        super(CrotpediaAuthInitial());

  Future<void> checkLoginStatus() async {
    try {
      if (_authManager.isLoggedIn) {
        // CrotpediaAuthManager might need to expose username or profile info
        // Assuming username is available or just using a placeholder/email if not
        emit(CrotpediaAuthSuccess(_authManager.username ?? 'User'));
      } else {
        // Attempt auto-login
        final success = await _authManager.tryAutoLogin();
        if (success) {
          emit(CrotpediaAuthSuccess(_authManager.username ?? 'User'));
        } else {
          emit(CrotpediaAuthInitial());
        }
      }
    } catch (e) {
      _logger.e('Failed to check login status', error: e);
      emit(CrotpediaAuthInitial());
    }
  }

  Future<void> login(String email, String password, bool rememberMe) async {
    emit(CrotpediaAuthLoading());
    try {
      final result = await _authManager.login(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );

      if (result.success) {
        emit(CrotpediaAuthSuccess(result.username ?? email.split('@').first));
      } else {
        emit(CrotpediaAuthError(result.errorMessage ?? 'Login failed'));
      }
    } catch (e) {
      _logger.e('Login error', error: e);
      emit(const CrotpediaAuthError(
          'An unexpected error occurred during login'));
    }
  }

  Future<void> logout() async {
    try {
      await _authManager.logout();
      emit(CrotpediaAuthInitial());
    } catch (e) {
      _logger.e('Logout error', error: e);
      // Even if logout fails, we probably want to show initial state to user
      emit(CrotpediaAuthInitial());
    }
  }
}
