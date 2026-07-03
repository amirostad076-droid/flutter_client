package com.fluxer

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Parcel
import com.google.firebase.messaging.RemoteMessage
import io.flutter.plugins.firebase.messaging.ContextHolder
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingBackgroundService
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingReceiver
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingStore
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingUtils
import io.flutter.plugins.firebase.messaging.FlutterFirebaseRemoteMessageLiveData

object FcmMessageForwarder {
    // Keep in sync with lib/core/push/fcm/fcm_gcm_notification_enrichment.dart
    fun enrichNotificationIntoData(bundle: Bundle) {
        if (!bundle.containsKey("title")) {
            val title = bundle.getString("gcm.notification.title")
            if (!title.isNullOrBlank()) {
                bundle.putString("title", title)
            }
        }
        if (!bundle.containsKey("body")) {
            val body = bundle.getString("gcm.notification.body")
            if (!body.isNullOrBlank()) {
                bundle.putString("body", body)
            }
        }
    }

    fun forwardMessage(context: Context, remoteMessage: RemoteMessage) {
        ensureApplicationContext(context)
        val messageId = remoteMessage.messageId
        if (remoteMessage.notification != null && messageId != null) {
            FlutterFirebaseMessagingReceiver.notifications[messageId] = remoteMessage
            FlutterFirebaseMessagingStore.getInstance().storeFirebaseMessage(remoteMessage)
        }
        if (FlutterFirebaseMessagingUtils.isApplicationForeground(context)) {
            FlutterFirebaseRemoteMessageLiveData.getInstance().postRemoteMessage(remoteMessage)
            return
        }
        val backgroundIntent =
            Intent(context, FlutterFirebaseMessagingBackgroundService::class.java)
        val parcel = Parcel.obtain()
        try {
            remoteMessage.writeToParcel(parcel, 0)
            backgroundIntent.putExtra(
                FlutterFirebaseMessagingUtils.EXTRA_REMOTE_MESSAGE,
                parcel.marshall(),
            )
            FlutterFirebaseMessagingBackgroundService.enqueueMessageProcessing(
                context,
                backgroundIntent,
                remoteMessage.originalPriority == RemoteMessage.PRIORITY_HIGH,
            )
        } finally {
            parcel.recycle()
        }
    }

    private fun ensureApplicationContext(context: Context) {
        if (ContextHolder.getApplicationContext() == null) {
            val appContext = context.applicationContext ?: context
            ContextHolder.setApplicationContext(appContext)
        }
    }
}
