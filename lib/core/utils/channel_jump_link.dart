class ChannelJumpLink {
  const ChannelJumpLink({required this.scope, required this.channelId});

  final String scope;
  final String channelId;

  bool get isDm => scope == '@me';
}

class MessageJumpLink extends ChannelJumpLink {
  const MessageJumpLink({
    required super.scope,
    required super.channelId,
    required this.messageId,
  });

  final String messageId;
}

const _kFluxerHosts = {'fluxer.app'};

bool _isSnowflake(String? s) {
  if (s == null || s.isEmpty) {
    return false;
  }
  return RegExp(r'^\d{15,21}$').hasMatch(s);
}

ChannelJumpLink? parseChannelJumpLink(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    return null;
  }
  if (!_kFluxerHosts.contains(uri.host)) {
    return null;
  }

  final parts = uri.pathSegments;
  if (parts.length < 3 || parts[0] != 'channels') {
    return null;
  }

  final scope = parts[1];
  final channelId = parts[2];

  final isDm = scope == '@me';
  if (!isDm && !_isSnowflake(scope)) {
    return null;
  }
  if (!_isSnowflake(channelId)) {
    return null;
  }

  if (parts.length >= 4 && _isSnowflake(parts[3])) {
    return MessageJumpLink(
      scope: scope,
      channelId: channelId,
      messageId: parts[3],
    );
  }

  return ChannelJumpLink(scope: scope, channelId: channelId);
}
