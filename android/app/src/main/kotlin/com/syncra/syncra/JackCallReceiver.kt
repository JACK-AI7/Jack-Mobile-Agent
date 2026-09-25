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
import android.media.AudioManager
import android.media.AudioAttributes
import android.speech.tts.TextToSpeech
import java.util.Locale

/**
 * JackCallReceiver — Detects incoming/outgoing/ended calls and notifies Flutter.
 * Autonomous AI Call Screener: Accepts call, activates speakerphone, and speaks
 * aloud directly to the caller via native Android TextToSpeech in British baritone voice.
 */
class JackCallReceiver : BroadcastReceiver() {

    companion object {
        const val CALL_CHANNEL = "com.jack.agent/calls"
        var callEventSink: io.flutter.plugin.common.EventChannel.EventSink? = null

        private var lastState = TelephonyManager.CALL_STATE_IDLE
        private var incomingNumber = ""
        private var callTts: TextToSpeech? = null
        private var isTtsInitialized = false

        fun sendEvent(data: Map<String, Any>) {
            Handler(Looper.getMainLooper()).post {
                callEventSink?.success(data)
            }
        }

        fun initCallTts(context: Context, onReady: (() -> Unit)? = null) {
            if (isTtsInitialized && callTts != null) {
                onReady?.invoke()
                return
            }
            callTts = TextToSpeech(context.applicationContext) { status ->
                if (status == TextToSpeech.SUCCESS) {
                    isTtsInitialized = true
                    try {
                        callTts?.setAudioAttributes(
                            AudioAttributes.Builder()
                                .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                                .build()
                        )
                        callTts?.setPitch(0.82f)
                        callTts?.setSpeechRate(0.92f)
                        val voices = callTts?.voices
                        val maleVoice = voices?.firstOrNull { v ->
                            val n = v.name.lowercase()
                            val l = v.locale.toLanguageTag().lowercase()
                            (l.contains("en-gb") || l.contains("en_gb")) &&
                            (n.contains("male") || n.contains("rjs") || n.contains("gbc") || n.contains("gbb") || n.contains("george")) &&
                            !n.contains("female")
                        } ?: voices?.firstOrNull { v ->
                            val n = v.name.lowercase()
                            val l = v.locale.language.lowercase()
                            l == "en" && (n.contains("male") || n.contains("baritone")) && !n.contains("female")
                        }
                        if (maleVoice != null) {
                            callTts?.voice = maleVoice
                        } else {
                            callTts?.language = Locale.UK
                        }
                    } catch (_: Exception) {}
                    onReady?.invoke()
                }
            }
        }

        fun speakCallGreeting(context: Context, contactName: String?) {
            val am = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            am.mode = AudioManager.MODE_IN_COMMUNICATION
            am.isSpeakerphoneOn = true

            val greeting = if (!contactName.isNullOrBlank() && contactName != "Unknown") {
                "Hello $contactName! I am Jack, the AI assistant. I am answering this call for the device owner. How may I assist you?"
            } else {
                "Hello! I am Jack, the AI assistant. I am answering this call for the device owner. Who is calling, and how may I assist you?"
            }

            initCallTts(context) {
                Handler(Looper.getMainLooper()).postDelayed({
                    try {
                        am.mode = AudioManager.MODE_IN_COMMUNICATION
                        am.isSpeakerphoneOn = true
                        callTts?.speak(greeting, TextToSpeech.QUEUE_FLUSH, null, "jack_call_greeting")
                    } catch (_: Exception) {}
                }, 750)
            }
        }

        fun stopSpeaking() {
            try {
                callTts?.stop()
            } catch (_: Exception) {}
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

        // Pre-initialize TTS on incoming call
        initCallTts(context)

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
                        try {
                            tm.acceptRingingCall()
                            val am = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                            am.mode = AudioManager.MODE_IN_COMMUNICATION
                            am.isSpeakerphoneOn = true

                            // Speak greeting to the caller natively
                            speakCallGreeting(context, contactName)
                        } catch (e: Exception) { e.printStackTrace() }
                    }
                }

                // Bring Jack UI to front to display live call transcript
                try {
                    val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                        putExtra("trigger_call_screener", true)
                        putExtra("caller_name", contactName ?: number)
                        putExtra("caller_number", number)
                    }
                    if (launchIntent != null) {
                        context.startActivity(launchIntent)
                    }
                } catch (_: Exception) {}
            }
            TelephonyManager.CALL_STATE_OFFHOOK -> {
                try {
                    val am = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    am.mode = AudioManager.MODE_IN_COMMUNICATION
                    am.isSpeakerphoneOn = true
                } catch (_: Exception) {}
                val contactName = resolveContactName(context, incomingNumber.ifEmpty { number })
                sendEvent(mapOf(
                    "event"       to "answered",
                    "number"      to (incomingNumber.ifEmpty { number }),
                    "contactName" to (contactName ?: number),
                ))

                // If not already spoken during ringing accept, speak now
                speakCallGreeting(context, contactName)
            }
            TelephonyManager.CALL_STATE_IDLE -> {
                stopSpeaking()
                try {
                    val am = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    am.isSpeakerphoneOn = false
                    am.mode = AudioManager.MODE_NORMAL
                } catch (_: Exception) {}
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
