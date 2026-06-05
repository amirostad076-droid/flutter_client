import Foundation

enum PushNotificationPayload {
  static func resolveThreadIdentifier(from userInfo: [AnyHashable: Any]) -> String? {
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
}
