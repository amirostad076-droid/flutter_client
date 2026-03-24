class IpAuthorizationChallenge {
  final String ticket;
  final String email;
  final int resendAvailableIn;

  const IpAuthorizationChallenge({
    required this.ticket,
    required this.email,
    required this.resendAvailableIn,
  });
}
