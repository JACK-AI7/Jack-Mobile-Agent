package com.syncra.syncra

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.telephony.TelephonyManager
import android.provider.ContactsContract
import android.database.Cursor

/**
 * JackCallReceiver — Passively detects call state transitions (ringing, answered, ended)
 * and relays status to Flutter for call logging without hijacking or interfering with cellular audio.
 */
class JackCallReceiver : BroadcastReceiver() {

    companion object {
        const val CALL_CHANNEL = "com.jack.agent/calls"
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
        if (intent.action == "android.intent.action.NEW_OUTGOING_CALL" ||
            intent.action == Intent.ACTION_NEW_OUTGOING_CALL) {
            val outgoingNum = intent.getStringExtra(Intent.EXTRA_PHONE_NUMBER) ?: ""
            if (outgoingNum.isNotBlank()) {
                incomingNumber = outgoingNum
                val contactName = resolveContactName(context, outgoingNum)
                sendEvent(mapOf(
                    "event"       to "outgoing",
                    "number"      to outgoingNum,
                    "contactName" to (contactName ?: outgoingNum),
                    "isContact"   to (contactName != null),
                ))
            }
            return
        }

        if (intent.action != TelephonyManager.ACTION_PHONE_STATE_CHANGED) return

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
