class AuthFailure implements Exception {
  final String message;
  final Map<String, String> fieldErrors;

  const AuthFailure(this.message, {this.fieldErrors = const {}});

  @override
  String toString() => message;
}
