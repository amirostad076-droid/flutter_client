import 'package:fluxer_app/features/auth/domain/auth_session.dart';

sealed class IpAuthPollResult {
  const IpAuthPollResult();
}

class IpAuthPending extends IpAuthPollResult {
  const IpAuthPending();
}

class IpAuthCompleted extends IpAuthPollResult {
  const IpAuthCompleted(this.session);

  final AuthSession session;
}

class IpAuthExpired extends IpAuthPollResult {
  const IpAuthExpired();
}
