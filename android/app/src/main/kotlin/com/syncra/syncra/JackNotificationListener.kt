package com.syncra.syncra

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.embedding.engine.FlutterEngineCache

/**
 * JackNotificationListener
 * ─────────────────────────────────────────────────────────────────────────────
 * Listens to ALL incoming notifications system-wide.
 * Forwards them to Flutter via EventChannel so Jack can:
 *   • Read WhatsApp/SMS messages aloud
 *   • Summarize notifications
 *   • Act on notifications by voice command
 */
class JackNotificationListener : NotificationListenerService() {

    companion object {
        var instance: JackNotificationListener? = null
        var onNotification: ((title: String, text: String, pkg: String) -> Unit)? = null

        // Packages to ignore (system noise)
        private val IGNORE_PACKAGES = setOf(
            "android",
            "com.android.systemui",
            "com.android.phone",
            "com.google.android.gms",
            "com.android.packageinstaller",
        )
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn ?: return
        if (sbn.packageName in IGNORE_PACKAGES) return

        val extras = sbn.notification?.extras ?: return
        val title  = extras.getCharSequence("android.title")?.toString() ?: return
        val text   = extras.getCharSequence("android.text")?.toString() ?: ""

        if (title.isBlank() && text.isBlank()) return

        // Fire callback to Flutter provider
        onNotification?.invoke(title, text, sbn.packageName)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {}
}
