import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kuron_crotpedia/kuron_crotpedia.dart';
import 'package:logger/logger.dart';
import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart' show CookieManager;

part 'crotpedia_auth_state.dart';

class CrotpediaAuthCubit extends Cubit<CrotpediaAuthState> {
  final CrotpediaSource _source;
  final Logger _logger;

  CrotpediaAuthCubit({
    required CrotpediaSource source,
    required Logger logger,
  })  : _source = source,
        _logger = logger,
        super(CrotpediaAuthInitial()) {
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    try {
      if (_source.isLoggedIn) {
        // CrotpediaAuthManager might need to expose username or profile info
        // Assuming username is available or just using a placeholder/email if not
        emit(CrotpediaAuthSuccess(_source.username ?? 'User'));
      } else {
        // Attempt auto-login
        final success = await _source.tryAutoLogin();
        if (success) {
          emit(CrotpediaAuthSuccess(_source.username ?? 'User'));
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
      final result = await _source.login(
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

  Future<void> externalLogin(String username, List<Cookie> cookies) async {
    emit(CrotpediaAuthLoading());
    try {
      await _source.setExternalSession(username: username, cookies: cookies);
      emit(CrotpediaAuthSuccess(username));
    } catch (e) {
      _logger.e('External login error', error: e);
      emit(const CrotpediaAuthError('Failed to capture session'));
    }
  }

  Future<void> logout() async {
    try {
      // Clear WebView cookies to ensure fresh login state next time
      await CookieManager.instance().deleteAllCookies();
      
      await _source.logout();
      emit(CrotpediaAuthInitial());
    } catch (e) {
      _logger.e('Logout error', error: e);
      // Even if logout fails, we probably want to show initial state to user
      emit(CrotpediaAuthInitial());
    }
  }
}
