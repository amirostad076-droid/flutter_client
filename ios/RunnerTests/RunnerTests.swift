import Flutter
import UIKit
import XCTest

class RunnerTests: XCTestCase {
  func testResolveChannelThreadIdentifierUsesApsThreadId() {
    let userInfo: [AnyHashable: Any] = [
      "aps": ["thread-id": "channel:456"],
      "message_id": "msg-1",
    ]
    XCTAssertEqual(
      PushNotificationPayload.resolveChannelThreadIdentifier(from: userInfo),
      "channel:456"
    )
    XCTAssertEqual(
      PushNotificationPayload.resolveThreadIdentifier(from: userInfo),
      "channel:456"
    )
  }

  func testResolveChannelThreadIdentifierFallsBackToChannelId() {
    let userInfo: [AnyHashable: Any] = [
      "channel_id": "456",
      "message_id": "msg-1",
    ]
    XCTAssertEqual(
      PushNotificationPayload.resolveChannelThreadIdentifier(from: userInfo),
      "456"
    )
  }

  func testResolveChannelThreadIdentifierFallsBackToNestedChannelId() {
    let userInfo: [AnyHashable: Any] = [
      "data": ["channel_id": "789"],
      "message_id": "msg-2",
    ]
    XCTAssertEqual(
      PushNotificationPayload.resolveChannelThreadIdentifier(from: userInfo),
      "789"
    )
  }

  func testResolveMessageIdFromTopLevelPayload() {
    let userInfo: [AnyHashable: Any] = [
      "message_id": "msg-1",
    ]
    XCTAssertEqual(PushNotificationPayload.resolveMessageId(from: userInfo), "msg-1")
  }

  func testResolveMessageIdFromNestedData() {
    let userInfo: [AnyHashable: Any] = [
      "data": ["message_id": "msg-nested"],
    ]
    XCTAssertEqual(PushNotificationPayload.resolveMessageId(from: userInfo), "msg-nested")
  }

  func testResolveMessageIdFallsBackToId() {
    let userInfo: [AnyHashable: Any] = [
      "id": "msg-fallback",
    ]
    XCTAssertEqual(PushNotificationPayload.resolveMessageId(from: userInfo), "msg-fallback")
  }

  func testResolveNotificationIdentifierUsesMessageId() {
    let userInfo: [AnyHashable: Any] = [
      "aps": ["thread-id": "channel:456"],
      "message_id": "msg-1",
    ]
    XCTAssertEqual(
      PushNotificationPayload.resolveNotificationIdentifier(from: userInfo),
      "msg-1"
    )
  }

  func testResolveNotificationIdentifierGeneratesUuidWhenMessageIdMissing() {
    let userInfo: [AnyHashable: Any] = [
      "aps": ["thread-id": "channel:456"],
    ]
    let identifier = PushNotificationPayload.resolveNotificationIdentifier(from: userInfo)
    XCTAssertFalse(identifier.isEmpty)
    XCTAssertNotEqual(identifier, "channel:456")
  }

  func testThreadAndNotificationIdentifiersAreIndependent() {
    let userInfo: [AnyHashable: Any] = [
      "aps": ["thread-id": "channel:456"],
      "message_id": "msg-1",
    ]
    let threadId = PushNotificationPayload.resolveChannelThreadIdentifier(from: userInfo)
    let notificationId = PushNotificationPayload.resolveNotificationIdentifier(from: userInfo)
    XCTAssertEqual(threadId, "channel:456")
    XCTAssertEqual(notificationId, "msg-1")
    XCTAssertNotEqual(threadId, notificationId)
  }
}
