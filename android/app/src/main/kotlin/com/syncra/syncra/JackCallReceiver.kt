package com.syncra.syncra

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.telephony.TelephonyManager
import android.provider.ContactsContract
import android.database.Cursor
import android.os.Build

/**
 * JackCallReceiver — Detects incoming/outgoing/ended calls and notifies Flutter.
 * Jack announces the caller name via TTS and offers post-call actions.
 */
class JackCallReceiver : BroadcastReceiver() {

    companion object {
        // EventChannel key used in MainActivity to send call events to Flutter
        const val CALL_CHANNEL = "com.syncra.syncra/calls"
        var callEventSink: io.flutter.plugin.common.EventChannel.EventSink? = null

        private var lastState = TelephonyManager.CALL_STATE_IDLE
        private var incomingNumber = ""

        fun sendEvent(data: Map<String, Any>) {
            Handler(Looper.getMainLooper()).post {
                callEventSink?.success(data)
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != TelephonyManager.ACTION_PHONE_STATE_CHANGED &&
            intent.action != "android.intent.action.NEW_OUTGOING_CALL") return

        val stateStr = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
        val number   = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
            ?: intent.getStringExtra("android.intent.extra.PHONE_NUMBER")
            ?: ""

        val state = when (stateStr) {
            TelephonyManager.EXTRA_STATE_RINGING  -> TelephonyManager.CALL_STATE_RINGING
            TelephonyManager.EXTRA_STATE_OFFHOOK  -> TelephonyManager.CALL_STATE_OFFHOOK
            TelephonyManager.EXTRA_STATE_IDLE     -> TelephonyManager.CALL_STATE_IDLE
            else -> return
        }

        // Only trigger on state transitions
        if (state == lastState) return

        when (state) {
            TelephonyManager.CALL_STATE_RINGING -> {
                incomingNumber = number
                val contactName = resolveContactName(context, number)
                sendEvent(mapOf(
                    "event"       to "incoming",
                    "number"      to number,
                    "contactName" to (contactName ?: number),
                    "isContact"   to (contactName != null),
                ))

                // Auto-answer the call for Jack to take over
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val tm = context.getSystemService(Context.TELECOM_SERVICE) as android.telecom.TelecomManager
                    if (context.checkSelfPermission(android.Manifest.permission.ANSWER_PHONE_CALLS) == android.content.pm.PackageManager.PERMISSION_GRANTED) {
                        try { tm.acceptRingingCall() } catch (e: Exception) { e.printStackTrace() }
                    }
                }
            }
            TelephonyManager.CALL_STATE_OFFHOOK -> {
                val contactName = resolveContactName(context, incomingNumber.ifEmpty { number })
                sendEvent(mapOf(
                    "event"       to "answered",
                    "number"      to (incomingNumber.ifEmpty { number }),
                    "contactName" to (contactName ?: number),
                ))
            }
            TelephonyManager.CALL_STATE_IDLE -> {
                val contactName = resolveContactName(context, incomingNumber.ifEmpty { number })
                sendEvent(mapOf(
                    "event"       to "ended",
                    "number"      to (incomingNumber.ifEmpty { number }),
                    "contactName" to (contactName ?: incomingNumber.ifEmpty { number }),
                ))
                incomingNumber = ""
            }
        }

        lastState = state
    }

    private fun resolveContactName(context: Context, number: String): String? {
        if (number.isBlank()) return null
        return try {
            val uri = android.net.Uri.withAppendedPath(
                ContactsContract.PhoneLookup.CONTENT_FILTER_URI,
                android.net.Uri.encode(number)
            )
            val cursor: Cursor? = context.contentResolver.query(
                uri,
                arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME),
                null, null, null
            )
            cursor?.use {
                if (it.moveToFirst()) it.getString(0) else null
            }
        } catch (_: Exception) { null }
    }
}
