import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../errors/error_handler.dart';

import 'package:nhasixapp/l10n/app_localizations.dart';

class ErrorMessageUtils {
  /// generate a user-friendly error message from any error object
  static String getFriendlyErrorMessage(dynamic error,
      [AppLocalizations? l10n]) {
    if (l10n != null) {
      return _getLocalizedMessage(error, l10n);
    }

    // Fallback to English/Default behavior if l10n is not provided (e.g. for logging)
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is SocketException) {
      return 'No internet connection. Please check your network settings.';
    } else if (error is TimeoutException) {
      return 'The operation timed out. Please try again later.';
    } else if (error is FormatException) {
      return 'Data format error. Please try again.';
    } else if (error is AppException) {
      return error.message;
    } else {
      // Clean up generic exceptions
      String msg = error.toString();
      if (msg.startsWith('Exception: ')) {
        msg = msg.substring(11);
      }
      return msg;
    }
  }

  static String _getLocalizedMessage(dynamic error, AppLocalizations l10n) {
    if (error is DioException) {
      return _handleLocalizedDioError(error, l10n);
    } else if (error is SocketException) {
      return l10n.errorNetwork;
    } else if (error is TimeoutException) {
      return l10n.errorConnectionTimeout;
    } else if (error is FormatException) {
      return l10n.errorParsing;
    } else if (error is AppException) {
      return error
          .message; // Custom app exceptions might already be localized or raw strings
    } else {
      return l10n.errorUnknown;
    }
  }

  static String _handleLocalizedDioError(
      DioException error, AppLocalizations l10n) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return l10n.errorConnectionTimeout;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        switch (statusCode) {
          case 400:
          case 401:
          case 403:
          case 404:
          case 500:
          case 502:
          case 503:
          case 504:
            return l10n
                .errorServer; // Simplified for now, can be more specific if needed
          default:
            return l10n.errorServer;
        }
      case DioExceptionType.cancel:
        return l10n.errorUnknown;
      case DioExceptionType.connectionError:
        if (error.error is SocketException) {
          return l10n.errorNetwork;
        }
        return l10n.errorConnectionRefused;
      case DioExceptionType.badCertificate:
        return l10n.errorNetwork; // logical grouping
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return l10n.errorNetwork;
        }
        final msg = error.message ?? '';
        if (msg.contains('SocketException') ||
            msg.contains('Connection reset')) {
          return l10n.errorNetwork;
        }
        return l10n.errorNetwork;
    }
  }

  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your internet connection.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        switch (statusCode) {
          case 400:
            return 'Invalid request (400). Please try again.';
          case 401:
          case 403:
            return 'Access denied. You may need to login or solve a captcha on the source website.';
          case 404:
            return 'Content not found (404). It might have been removed.';
          case 500:
          case 502:
          case 503:
          case 504:
            return 'Server error ($statusCode). The source website is experiencing issues.';
          default:
            return 'Server error (${statusCode ?? "Unknown"}).';
        }
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        if (error.error is SocketException) {
          return 'No internet connection. Please check your network settings.';
        }
        return 'Connection failed. Please check your internet connection.';
      case DioExceptionType.badCertificate:
        return 'Security certificate error. Connection unsafe.';
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return 'No internet connection. Please check your network settings.';
        }
        final msg = error.message ?? 'Unknown network error';
        if (msg.contains('SocketException') ||
            msg.contains('Connection reset')) {
          return 'Network connection interrupted. Please try again.';
        }
        return 'Network error occurred. Please try again.';
    }
  }
}
