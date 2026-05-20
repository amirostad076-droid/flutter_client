//
//  NotificationService.swift
//  NotificationService
//
//  Created by Elias Deuss on 15/05/2026.
//
//

import Foundation
import UserNotifications

final class NotificationService: UNNotificationServiceExtension {
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?
    private var fallbackContent: UNNotificationContent?
    private var didDeliver: Bool = false
    private let deliverLock = NSLock()
    private static let maxDownloadBytes: Int64 = 5 * 1024 * 1024

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        fallbackContent = request.content
        guard let mutableContent = request.content.mutableCopy() as? UNMutableNotificationContent else {
            deliver(content: request.content)
            return
        }
        bestAttemptContent = mutableContent
        guard let imageUrl = Self.resolveImageUrl(from: request.content.userInfo) else {
            deliver(content: mutableContent)
            return
        }
        Self.downloadImage(from: imageUrl) { localFileUrl in
            self.deliverLock.lock()
            let alreadyDelivered = self.didDeliver
            self.deliverLock.unlock()
            if alreadyDelivered {
                if let fileURL = localFileUrl {
                    try? FileManager.default.removeItem(at: fileURL)
                }
                return
            }
            if let mutableContent = self.bestAttemptContent, let fileURL = localFileUrl {
                do {
                    let attachment = try UNNotificationAttachment(identifier: "fluxer.message.image", url: fileURL, options: nil)
                    mutableContent.attachments = [attachment]
                } catch {
                    // Deliver without attachment.
                }
                try? FileManager.default.removeItem(at: fileURL)
            }
            if let mutable = self.bestAttemptContent {
                self.deliver(content: mutable)
            } else if let fallback = self.fallbackContent {
                self.deliver(content: fallback)
            }
        }
    }

    override func serviceExtensionTimeWillExpire() {
        let content: UNNotificationContent = bestAttemptContent ?? fallbackContent ?? UNNotificationContent()
        deliver(content: content)
    }

    private func deliver(content: UNNotificationContent) {
        deliverLock.lock()
        defer { deliverLock.unlock() }
        guard !didDeliver else {
            return
        }
        didDeliver = true
        let handler = contentHandler
        contentHandler = nil
        handler?(content)
    }
}

private extension NotificationService {
    static func resolveImageUrl(from userInfo: [AnyHashable: Any]) -> URL? {
        if let hasMedia = userInfo["has_media"] as? Bool, !hasMedia {
            return nil
        }
        if let hasMedia = userInfo["has_media"] as? NSNumber, !hasMedia.boolValue {
            return nil
        }
        if let hasMediaString = userInfo["has_media"] as? String, hasMediaString.lowercased() == "false" {
            return nil
        }
        for key in ["image_url", "image"] {
            guard let raw = userInfo[key] as? String else {
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

    static func downloadImage(from url: URL, completion: @escaping (URL?) -> Void) {
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 25
        let session = URLSession(configuration: configuration)
        let task = session.dataTask(with: request) { data, response, error in
            session.invalidateAndCancel()
            if error != nil {
                completion(nil)
                return
            }
            guard let data, !data.isEmpty else {
                completion(nil)
                return
            }
            if Int64(data.count) > maxDownloadBytes {
                completion(nil)
                return
            }
            if let http = response as? HTTPURLResponse, let lengthHeader = http.value(forHTTPHeaderField: "Content-Length"), let declared = Int64(lengthHeader), declared > maxDownloadBytes {
                completion(nil)
                return
            }
            let mime = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Content-Type")?.lowercased()
            let ext = fileExtension(from: url, mimeType: mime, data: data)
            let destination = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ext)
            do {
                try data.write(to: destination, options: .atomic)
                completion(destination)
            } catch {
                completion(nil)
            }
        }
        task.resume()
    }

    static func fileExtension(from url: URL, mimeType: String?, data: Data) -> String {
        if let mime = mimeType {
            if mime.contains("jpeg") || mime.contains("jpg") {
                return ".jpg"
            }
            if mime.contains("png") {
                return ".png"
            }
            if mime.contains("gif") {
                return ".gif"
            }
            if mime.contains("webp") {
                return ".webp"
            }
            if mime.contains("heic") || mime.contains("heif") {
                return ".heic"
            }
        }
        let pathExt = url.pathExtension.lowercased()
        let allowed = ["png", "jpg", "jpeg", "gif", "webp", "heic", "heif"]
        if allowed.contains(pathExt) {
            if pathExt == "jpeg" || pathExt == "jpg" {
                return ".jpg"
            }
            return ".\(pathExt)"
        }
        return sniffExtension(from: data) ?? ".jpg"
    }

    static func sniffExtension(from data: Data) -> String? {
        guard !data.isEmpty else {
            return nil
        }
        let prefix = [UInt8](data.prefix(min(16, data.count)))
        if prefix.count >= 3, prefix[0] == 0xFF, prefix[1] == 0xD8, prefix[2] == 0xFF {
            return ".jpg"
        }
        if prefix.count >= 8, prefix[0] == 0x89, prefix[1] == 0x50, prefix[2] == 0x4E, prefix[3] == 0x47 {
            return ".png"
        }
        if prefix.count >= 6, prefix[0] == 0x47, prefix[1] == 0x49, prefix[2] == 0x46 {
            return ".gif"
        }
        if prefix.count >= 12 {
            let start = Data(prefix[0..<4])
            let webp = Data(prefix[8..<12])
            if String(data: start, encoding: .ascii) == "RIFF" && String(data: webp, encoding: .ascii) == "WEBP" {
                return ".webp"
            }
        }
        return nil
    }
}
