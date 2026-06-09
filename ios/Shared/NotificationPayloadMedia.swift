//
//  NotificationPayloadMedia.swift
//  NotificationPayloadMedia
//
//  Created by Elias Deuss on 09/06/2026.
//
//

import Foundation

enum NotificationPayloadMedia {
  static func resolveImageUrl(from userInfo: [AnyHashable: Any]) -> URL? {
    if isMediaDisabled(in: userInfo) {
      return nil
    }
    if let nested = userInfo["data"] as? [AnyHashable: Any] {
      if isMediaDisabled(in: nested) {
        return nil
      }
      if let url = imageUrl(in: nested) {
        return url
      }
    }
    return imageUrl(in: userInfo)
  }

  static func isMediaDisabled(in payload: [AnyHashable: Any]) -> Bool {
    if let hasMedia = payload["has_media"] as? Bool, !hasMedia {
      return true
    }
    if let hasMedia = payload["has_media"] as? NSNumber, !hasMedia.boolValue {
      return true
    }
    if let hasMediaString = payload["has_media"] as? String, hasMediaString.lowercased() == "false" {
      return true
    }
    return false
  }

  private static func imageUrl(in payload: [AnyHashable: Any]) -> URL? {
    for key in ["image_url", "image"] {
      guard let raw = payload[key] as? String else {
        continue
      }
      let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else {
        continue
      }
      guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased() else {
        continue
      }
      if scheme == "https" || scheme == "http" {
        return url
      }
    }
    return nil
  }
}
