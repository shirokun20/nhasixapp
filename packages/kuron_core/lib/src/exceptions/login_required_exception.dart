/// Exception thrown when content requires authentication
class LoginRequiredException implements Exception {
  final String message;
  final String? loginUrl;

  LoginRequiredException(this.message, {this.loginUrl});

  @override
  String toString() => 'LoginRequiredException: $message';
}
