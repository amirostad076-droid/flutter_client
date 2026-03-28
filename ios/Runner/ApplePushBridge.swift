import Flutter
import UIKit
import UserNotifications

final class ApplePushBridge: NSObject, FlutterStreamHandler {
  static let shared = ApplePushBridge()

  private static let methodChannelName = "fluxer_app/apple_push"
  private static let eventChannelName = "fluxer_app/apple_push/messages"

  private var deviceTokenHex: String?
  private var eventSink: FlutterEventSink?
  private var isRegisteredWithEngine = false

  private override init() {
    super.init()
  }

  func configureNotificationCenterDelegate() {
    UNUserNotificationCenter.current().delegate = self
  }

  func register(engineBridge: FlutterImplicitEngineBridge) {
    if isRegisteredWithEngine {
      return
    }
    isRegisteredWithEngine = true
    let messenger = engineBridge.applicationRegistrar.messenger()
    let methodChannel = FlutterMethodChannel(
      name: Self.methodChannelName,
      binaryMessenger: messenger
    )
    methodChannel.setMethodCallHandler { call, result in
      Self.shared.handleMethodCall(call, result: result)
    }
    let eventChannel = FlutterEventChannel(
      name: Self.eventChannelName,
      binaryMessenger: messenger
    )
    eventChannel.setStreamHandler(self)
  }

  func setDeviceToken(_ deviceToken: Data) {
    let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
    if Thread.isMainThread {
      deviceTokenHex = hex
    } else {
      DispatchQueue.main.async {
        self.deviceTokenHex = hex
      }
    }
  }

  func clearDeviceTokenOnFailure() {
    if Thread.isMainThread {
      deviceTokenHex = nil
    } else {
      DispatchQueue.main.async {
        self.deviceTokenHex = nil
      }
    }
  }

  func emitPushMessage(userInfo: [AnyHashable: Any], messageId: String?) {
    let payload = Self.flattenUserInfo(userInfo)
    var title: String?
    var body: String?
    if let aps = userInfo["aps"] as? [String: Any] {
      if let alert = aps["alert"] as? [String: Any] {
        title = alert["title"] as? String
        body = alert["body"] as? String
      } else if let alert = aps["alert"] as? String {
        body = alert
      }
    }
    let id = messageId ?? UUID().uuidString
    var notification: [String: Any] = [:]
    if let title = title {
      notification["title"] = title
    }
    if let body = body {
      notification["body"] = body
    }
    let event: [String: Any] = [
      "messageId": id,
      "notification": notification,
      "data": payload,
    ]
    DispatchQueue.main.async {
      guard let sink = self.eventSink else {
        return
      }
      sink(event)
    }
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "registerRemoteNotifications":
      DispatchQueue.main.async {
        UIApplication.shared.registerForRemoteNotifications()
        result(nil)
      }
    case "getDeviceToken":
      DispatchQueue.main.async {
        result(self.deviceTokenHex)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func flattenUserInfo(_ userInfo: [AnyHashable: Any]) -> [String: String] {
    var out: [String: String] = [:]
    for (key, value) in userInfo {
      guard (key as? String) != "aps" else {
        continue
      }
      let keyString = String(describing: key)
      if let dict = value as? [String: Any] {
        if let data = try? JSONSerialization.data(withJSONObject: dict),
          let string = String(data: data, encoding: .utf8)
        {
          out[keyString] = string
        } else {
          out[keyString] = String(describing: value)
        }
      } else if let array = value as? [Any] {
        if let data = try? JSONSerialization.data(withJSONObject: array),
          let string = String(data: data, encoding: .utf8)
        {
          out[keyString] = string
        } else {
          out[keyString] = String(describing: value)
        }
      } else {
        out[keyString] = "\(value)"
      }
    }
    return out
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}

extension ApplePushBridge: UNUserNotificationCenterDelegate {
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo
    emitPushMessage(userInfo: userInfo, messageId: notification.request.identifier)
    completionHandler([.banner, .badge, .sound])
  }
}
