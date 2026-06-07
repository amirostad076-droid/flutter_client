import Foundation

/// APNs payload helpers: channel `thread-id` for grouping, `message_id` for per-message identity.
/// Remote pushes need a per-message `apns-collapse-id` (or none); channel-scoped collapse replaces prior messages.
enum PushNotificationPayload {
  static func resolveThreadIdentifier(from userInfo: [AnyHashable: Any]) -> String? {
    resolveChannelThreadIdentifier(from: userInfo)
  }

  static func resolveChannelThreadIdentifier(from userInfo: [AnyHashable: Any]) -> String? {
    if let aps = userInfo["aps"] as? [AnyHashable: Any],
      let threadId = aps["thread-id"] as? String, !threadId.isEmpty
    {
      return threadId
    }
    if let channelId = userInfo["channel_id"] as? String, !channelId.isEmpty {
      return channelId
    }
    if let data = userInfo["data"] as? [AnyHashable: Any],
      let channelId = data["channel_id"] as? String, !channelId.isEmpty
    {
      return channelId
    }
    return nil
  }

  static func resolveMessageId(from userInfo: [AnyHashable: Any]) -> String? {
    if let messageId = userInfo["message_id"] as? String, !messageId.isEmpty {
      return messageId
    }
    if let data = userInfo["data"] as? [AnyHashable: Any] {
      if let messageId = data["message_id"] as? String, !messageId.isEmpty {
        return messageId
      }
    }
    if let id = userInfo["id"] as? String, !id.isEmpty {
      return id
    }
    if let data = userInfo["data"] as? [AnyHashable: Any],
      let id = data["id"] as? String, !id.isEmpty
    {
      return id
    }
    return nil
  }

  static func resolveNotificationIdentifier(from userInfo: [AnyHashable: Any]) -> String {
    resolveMessageId(from: userInfo) ?? UUID().uuidString
  }
}
