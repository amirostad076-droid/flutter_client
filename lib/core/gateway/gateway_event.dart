/// Event types received from the Fluxer gateway WebSocket.
enum GatewayEventType {
  ready,
  messageCreate,
  messageUpdate,
  messageDelete,
  typingStart,
  presenceUpdate,
  guildMemberAdd,
  guildMemberRemove,
  guildMemberUpdate,
  channelCreate,
  channelUpdate,
  channelDelete,
}

/// Parses a gateway event type string to [GatewayEventType].
GatewayEventType? parseGatewayEvent(String type) {
  switch (type) {
    case 'READY':
      return GatewayEventType.ready;
    case 'MESSAGE_CREATE':
      return GatewayEventType.messageCreate;
    case 'MESSAGE_UPDATE':
      return GatewayEventType.messageUpdate;
    case 'MESSAGE_DELETE':
      return GatewayEventType.messageDelete;
    case 'TYPING_START':
      return GatewayEventType.typingStart;
    case 'PRESENCE_UPDATE':
      return GatewayEventType.presenceUpdate;
    case 'GUILD_MEMBER_ADD':
      return GatewayEventType.guildMemberAdd;
    case 'GUILD_MEMBER_REMOVE':
      return GatewayEventType.guildMemberRemove;
    case 'GUILD_MEMBER_UPDATE':
      return GatewayEventType.guildMemberUpdate;
    case 'CHANNEL_CREATE':
      return GatewayEventType.channelCreate;
    case 'CHANNEL_UPDATE':
      return GatewayEventType.channelUpdate;
    case 'CHANNEL_DELETE':
      return GatewayEventType.channelDelete;
    default:
      return null;
  }
}
