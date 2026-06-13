package com.fluxer

import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class NotificationCancelBridge(
    private val context: Context,
) {
    fun register(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                METHOD_CANCEL_FOR_CHANNEL -> {
                    val channelId = call.argument<String>(ARG_CHANNEL_ID)
                    if (channelId.isNullOrEmpty()) {
                        result.error("invalid_args", "channelId is required", null)
                        return@setMethodCallHandler
                    }
                    val cancelled = cancelForChannel(channelId)
                    result.success(cancelled)
                }
                METHOD_CANCEL_ALL -> {
                    cancelAll()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun cancelAll() {
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancelAll()
    }

    private fun cancelForChannel(channelId: String): Int {
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelTag = "channel:$channelId"
        val channelPrefix = "$channelTag:"
        var cancelled = 0
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return 0
        }
        for (status in manager.activeNotifications) {
            if (!notificationMatchesChannel(status, channelId, channelTag, channelPrefix)) {
                continue
            }
            manager.cancel(status.tag, status.id)
            cancelled++
        }
        return cancelled
    }

    private fun notificationMatchesChannel(
        status: android.service.notification.StatusBarNotification,
        channelId: String,
        channelTag: String,
        channelPrefix: String,
    ): Boolean {
        val tag = status.tag
        if (tag == channelTag || (tag != null && tag.startsWith(channelPrefix))) {
            return true
        }
        val extras = status.notification.extras ?: return false
        if (extras.getString(EXTRA_CHANNEL_ID) == channelId) {
            return true
        }
        val dataTag = extras.getString(EXTRA_TAG)
        if (dataTag == channelTag || (dataTag != null && dataTag.startsWith(channelPrefix))) {
            return true
        }
        val notificationTag = extras.getString(EXTRA_NOTIFICATION_TAG)
        if (
            notificationTag == channelTag ||
                (notificationTag != null && notificationTag.startsWith(channelPrefix))
        ) {
            return true
        }
        val url = extras.getString(EXTRA_URL) ?: extras.getString(EXTRA_NAVIGATE)
        val urlChannelId = extractChannelIdFromPath(url)
        if (urlChannelId == channelId) {
            return true
        }
        return matchesNestedDataExtras(extras, channelId, channelTag, channelPrefix)
    }

    private fun matchesNestedDataExtras(
        extras: Bundle,
        channelId: String,
        channelTag: String,
        channelPrefix: String,
    ): Boolean {
        val nested = extras.getString(EXTRA_DATA) ?: return false
        if (nested.contains("\"channel_id\":\"$channelId\"") ||
            nested.contains("\"channel_id\": \"$channelId\"")
        ) {
            return true
        }
        if (nested.contains("\"tag\":\"$channelTag\"") ||
            nested.contains("\"notification_tag\":\"$channelTag\"")
        ) {
            return true
        }
        val urlChannelId =
            extractChannelIdFromPath(extractJsonStringValue(nested, "url")) ?:
                extractChannelIdFromPath(extractJsonStringValue(nested, "navigate"))
        return urlChannelId == channelId
    }

    private fun extractJsonStringValue(json: String, key: String): String? {
        val pattern = Regex(""""$key"\s*:\s*"([^"]+)"""")
        return pattern.find(json)?.groupValues?.getOrNull(1)
    }

    private fun extractChannelIdFromPath(path: String?): String? {
        if (path.isNullOrEmpty()) {
            return null
        }
        var normalized = path.trim()
        if (normalized.startsWith("http://") || normalized.startsWith("https://")) {
            normalized = normalized.substringAfter("://").substringAfter('/')
            normalized = "/$normalized"
        }
        if (!normalized.startsWith("/channels/")) {
            return null
        }
        val dmMessage = Regex("""^/channels/@me/([^/]+)""").find(normalized)
        if (dmMessage != null) {
            return dmMessage.groupValues.getOrNull(1)
        }
        val guildMessage =
            Regex("""^/channels/[^@/][^/]*/([^/]+)""").find(normalized)
        if (guildMessage != null && guildMessage.groupValues.getOrNull(1) != "members") {
            return guildMessage.groupValues.getOrNull(1)
        }
        return null
    }

    companion object {
        const val CHANNEL_NAME = "fluxer_app/android_notifications"
        const val METHOD_CANCEL_FOR_CHANNEL = "cancelForChannel"
        const val METHOD_CANCEL_ALL = "cancelAll"
        const val ARG_CHANNEL_ID = "channelId"
        private const val EXTRA_CHANNEL_ID = "channel_id"
        private const val EXTRA_TAG = "tag"
        private const val EXTRA_NOTIFICATION_TAG = "notification_tag"
        private const val EXTRA_URL = "url"
        private const val EXTRA_NAVIGATE = "navigate"
        private const val EXTRA_DATA = "data"
    }
}
