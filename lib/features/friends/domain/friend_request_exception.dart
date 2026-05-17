class FriendRequestException implements Exception {
  const FriendRequestException({this.code, this.message});

  final String? code;
  final String? message;

  @override
  String toString() => message ?? code ?? 'FriendRequestException';
}
