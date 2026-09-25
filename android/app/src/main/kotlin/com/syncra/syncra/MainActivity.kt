package com.syncra.syncra

import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager
import android.media.AudioAttributes
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.provider.Settings
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.os.Handler
import android.os.Looper
import android.provider.ContactsContract
import android.bluetooth.BluetoothAdapter
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CameraCharacteristics
import android.accessibilityservice.AccessibilityService as A11ySvc
import com.syncra.syncra.service.JackMasterAccessibilityService
import com.syncra.syncra.service.JackShizukuManager
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch
import java.util.Locale


class MainActivity : FlutterActivity() {
    companion object {
        var overlayChannel: MethodChannel? = null
        var isForeground = false

        fun triggerJackListen() {
            Handler(Looper.getMainLooper()).post {
                overlayChannel?.invokeMethod("onBubbleTapped", null)
            }
        }

        fun onPillClosed() {
            Handler(Looper.getMainLooper()).post {
                overlayChannel?.invokeMethod("onPillDismissed", null)
            }
        }
    }

    private val DOM_CHANNEL     = "com.jack.agent/accessibility"
    private val OVERLAY_CHANNEL = "com.jack.agent/overlay"
    private val NOTIF_CHANNEL   = "com.jack.agent/notifications"
    private val CALL_CHANNEL    = "com.jack.agent/calls"
    private val CALL_TALK_CHANNEL = "com.jack.agent/call_talk"
    private val SHIZUKU_CHANNEL = "com.jack.agent/shizuku"

    private var callTts: TextToSpeech? = null
    private var shizukuInitialized = false

    // Hide bubble when the Jack app itself is open; show outside the app
    override fun onResume() {
        super.onResume()
        isForeground = true
        JackOverlayService.instance?.hideAll()
        // Initialize Shizuku Binder listeners (idempotent — safe to call on each resume)
        if (!shizukuInitialized) {
            JackShizukuManager.initialize()
            shizukuInitialized = true
        }
    }

    override fun onPause() {
        super.onPause()
        isForeground = false
        if (Settings.canDrawOverlays(this)) {
            val i = Intent(this, JackOverlayService::class.java).apply {
                putExtra(JackOverlayService.EXTRA_MODE, JackOverlayService.MODE_LISTENING)
            }
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(i)
                } else {
                    startService(i)
                }
            } catch (e: Exception) {
                android.util.Log.e("MainActivity", "Failed to start JackOverlayService: ${e.message}")
            }
            JackOverlayService.instance?.showBubble()
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expected1 = "$packageName/${JackAccessibilityService::class.java.name}"
        val expected2 = "$packageName/${JackMasterAccessibilityService::class.java.name}"
        val enabledServices = android.provider.Settings.Secure.getString(
            contentResolver, android.provider.Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        val colonSplitter = android.text.TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(enabledServices)
        while (colonSplitter.hasNext()) {
            val item = colonSplitter.next()
            if (item.equals(expected1, ignoreCase = true) || item.equals(expected2, ignoreCase = true)) {
                return true
            }
        }
        return false
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val expected = "$packageName/${JackNotificationListener::class.java.name}"
        val enabledListeners = android.provider.Settings.Secure.getString(
            contentResolver, "enabled_notification_listeners"
        ) ?: return false
        return enabledListeners.contains(expected)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Init Call Talk TTS engine (Strictly Male British Baritone)
        callTts = TextToSpeech(this) { status ->
            if (status == TextToSpeech.SUCCESS) {
                callTts?.setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build()
                )
                callTts?.setPitch(0.82f)
                callTts?.setSpeechRate(0.92f)
                try {
                    val voices = callTts?.voices
                    val maleVoice = voices?.firstOrNull { v ->
                        val n = v.name.lowercase()
                        val l = v.locale.toLanguageTag().lowercase()
                        (l.contains("en-gb") || l.contains("en_gb")) &&
                        (n.contains("male") || n.contains("rjs") || n.contains("gbc") || n.contains("gbb") || n.contains("george")) &&
                        !n.contains("female") && !n.contains("gba") && !n.contains("gbf")
                    } ?: voices?.firstOrNull { v ->
                        val n = v.name.lowercase()
                        val l = v.locale.language.lowercase()
                        l == "en" && (n.contains("male") || n.contains("baritone") || n.contains("sfg") || n.contains("tpd")) &&
                        !n.contains("female") && !n.contains("woman") && !n.contains("gba") && !n.contains("gbf")
                    }
                    if (maleVoice != null) {
                        callTts?.voice = maleVoice
                    } else {
                        callTts?.language = Locale.UK
                    }
                } catch (_: Exception) {}
            }
        }

        // ── Call Talk Channel ───────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALL_TALK_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "speak" -> {
                        val text = call.argument<String>("text") ?: ""
                        callTts?.setPitch(0.82f)
                        callTts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "call_talk")
                        result.success(true)
                    }
                    "stop" -> {
                        callTts?.stop()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // ── DOM Automation Channel ────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DOM_CHANNEL)
            .setMethodCallHandler { call, result ->
                val svc = JackAccessibilityService.instance
                when (call.method) {
                    "clickText"       -> result.success(svc?.performClickOnText(call.argument<String>("text") ?: "") ?: false)
                    "clickCoordinates" -> {
                        val x = call.argument<Double>("x")?.toFloat() ?: 0f
                        val y = call.argument<Double>("y")?.toFloat() ?: 0f
                        result.success(svc?.clickCoordinates(x, y) ?: false)
                    }
                    "captureScreen"   -> {
                        svc?.captureScreen { bytes ->
                            result.success(bytes)
                        }
                    }
                    "longPressText"   -> result.success(svc?.performLongPressOnText(call.argument<String>("text") ?: "") ?: false)
                    "typeText"        -> result.success(svc?.performTypeText(call.argument<String>("text") ?: "") ?: false)
                    "swipeUp"         -> { svc?.performSwipeUp(); result.success(true) }
                    "swipeDown"       -> { svc?.performSwipeDown(); result.success(true) }
                    "swipeLeft"       -> { svc?.performSwipeLeft(); result.success(true) }
                    "swipeRight"      -> { svc?.performSwipeRight(); result.success(true) }
                    "scrollForward"   -> result.success(svc?.performScrollForward() ?: false)
                    "scrollBackward"  -> result.success(svc?.performScrollBackward() ?: false)
                    "pressEnter"      -> result.success(svc?.performPressEnter() ?: false)
                    "pressBack"       -> { svc?.performBack(); result.success(true) }
                    "pressHome"       -> { svc?.performHome(); result.success(true) }
                    "pressRecents"    -> { svc?.performRecents(); result.success(true) }
                    "pullNotifications"  -> { svc?.performNotifications(); result.success(true) }
                    "pullQuickSettings"  -> { svc?.performQuickSettings(); result.success(true) }
                    "launchApp"       -> {
                        val pkg = call.argument<String>("package")
                        if (pkg != null) {
                            try {
                                // Try via AccessibilityService first (works even from background)
                                val launched = svc?.performLaunchApp(pkg) ?: false
                                if (!launched) {
                                    // Fallback: use MainActivity context
                                    val launchIntent = packageManager.getLaunchIntentForPackage(pkg)
                                    if (launchIntent != null) {
                                        launchIntent.addFlags(
                                            Intent.FLAG_ACTIVITY_NEW_TASK or
                                            Intent.FLAG_ACTIVITY_CLEAR_TOP or
                                            Intent.FLAG_ACTIVITY_SINGLE_TOP
                                        )
                                        startActivity(launchIntent)
                                        result.success(true)
                                    } else {
                                        result.success(false)
                                    }
                                } else {
                                    result.success(true)
                                }
                            } catch (ex: Exception) {
                                result.success(false)
                            }
                        } else {
                            result.success(false)
                        }
                    }
                    "openUrl"         -> {
                        val url = call.argument<String>("url")
                        if (url != null) {
                            try {
                                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                result.success(true)
                            } catch (e: Exception) {
                                result.success(false)
                            }
                        } else {
                            result.success(false)
                        }
                    }
                    "directCall"      -> {
                        var num = call.argument<String>("number")
                        if (num != null) {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && checkSelfPermission(android.Manifest.permission.CALL_PHONE) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                                result.success("NO_PERMISSION")
                                return@setMethodCallHandler
                            }
                            // If num contains letters, try to resolve it from Contacts
                            if (num.any { it.isLetter() }) {
                                val resolved = resolveContactNumber(num)
                                if (resolved != null) {
                                    num = resolved
                                } else {
                                    result.success("NOT_FOUND")
                                    return@setMethodCallHandler
                                }
                            }
                            try {
                                val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$num"))
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(intent)
                                result.success("SUCCESS")
                            } catch (e: Exception) {
                                result.success("ERROR")
                            }
                        } else {
                            result.success("ERROR")
                        }
                    }
                    "endCall" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                                val tm = getSystemService(TELECOM_SERVICE) as android.telecom.TelecomManager
                                if (checkSelfPermission(android.Manifest.permission.ANSWER_PHONE_CALLS) == android.content.pm.PackageManager.PERMISSION_GRANTED) {
                                    val ended = tm.endCall()
                                    result.success(ended)
                                    return@setMethodCallHandler
                                }
                            }
                            result.success(false)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "answerCall" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                val tm = getSystemService(TELECOM_SERVICE) as android.telecom.TelecomManager
                                if (checkSelfPermission(android.Manifest.permission.ANSWER_PHONE_CALLS) == android.content.pm.PackageManager.PERMISSION_GRANTED) {
                                    tm.acceptRingingCall()
                                    result.success(true)
                                    return@setMethodCallHandler
                                }
                            }
                            result.success(false)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "searchContact" -> {
                        val name = call.argument<String>("name") ?: ""
                        val num = resolveContactNumber(name)
                        if (num != null) result.success(num)
                        else result.success("Contact not found")
                    }
                    "getCalendarEvents" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && checkSelfPermission(android.Manifest.permission.READ_CALENDAR) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                            result.success("Error: Missing Calendar Permission")
                            return@setMethodCallHandler
                        }
                        try {
                            val uri = android.provider.CalendarContract.Events.CONTENT_URI
                            val projection = arrayOf(
                                android.provider.CalendarContract.Events.TITLE,
                                android.provider.CalendarContract.Events.DTSTART
                            )
                            val now = System.currentTimeMillis()
                            val selection = "${android.provider.CalendarContract.Events.DTSTART} >= ?"
                            val selectionArgs = arrayOf(now.toString())
                            val sortOrder = "${android.provider.CalendarContract.Events.DTSTART} ASC LIMIT 5"

                            val sb = StringBuilder()
                            contentResolver.query(uri, projection, selection, selectionArgs, sortOrder)?.use { cursor ->
                                while (cursor.moveToNext()) {
                                    val title = cursor.getString(0)
                                    val start = cursor.getLong(1)
                                    val date = java.text.SimpleDateFormat("MMM dd, hh:mm a", java.util.Locale.getDefault()).format(java.util.Date(start))
                                    sb.append("- $title at $date\n")
                                }
                            }
                            if (sb.isEmpty()) result.success("No upcoming events found.")
                            else result.success(sb.toString().trim())
                        } catch (e: Exception) {
                            result.success("Error reading calendar: ${e.message}")
                        }
                    }
                    "getScreenText"   -> result.success(svc?.getScreenText() ?: "")
                    "getBatteryLevel" -> {
                        val ifilter  = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
                        val battery  = applicationContext.registerReceiver(null, ifilter)
                        val level    = battery?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
                        val scale    = battery?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
                        val pct      = if (level >= 0 && scale > 0) (level * 100 / scale) else -1
                        result.success(pct)
                    }
                    "lockScreen" -> {
                        val success = svc?.performLockScreen() == true
                        result.success(success)
                    }
                    "setVolume" -> {
                        val level = call.argument<Int>("level") ?: 50
                        val am = getSystemService(AUDIO_SERVICE) as AudioManager
                        val max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                        val target = (level * max / 100).coerceIn(0, max)
                        am.setStreamVolume(AudioManager.STREAM_MUSIC, target, AudioManager.FLAG_SHOW_UI)
                        result.success(true)
                    }
                    "toggleBluetooth" -> {
                        val enable = call.argument<Boolean>("enable") ?: false
                        try {
                            val btManager = getSystemService(BLUETOOTH_SERVICE) as? android.bluetooth.BluetoothManager
                            val adapter = btManager?.adapter
                            if (adapter != null) {
                                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                                    @Suppress("DEPRECATION")
                                    if (enable) adapter.enable() else adapter.disable()
                                    result.success(true)
                                } else {
                                    val intent = Intent(if (enable) BluetoothAdapter.ACTION_REQUEST_ENABLE else Settings.ACTION_BLUETOOTH_SETTINGS).apply {
                                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    }
                                    startActivity(intent)
                                    result.success(true)
                                }
                            } else {
                                val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            try {
                                val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                result.success(true)
                            } catch (_: Exception) {
                                result.success(false)
                            }
                        }
                    }
                    "toggleWifi" -> {
                        val enable = call.argument<Boolean>("enable") ?: false
                        try {
                            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                                val wm = applicationContext.getSystemService(WIFI_SERVICE) as? android.net.wifi.WifiManager
                                @Suppress("DEPRECATION")
                                wm?.isWifiEnabled = enable
                                result.success(true)
                            } else {
                                val intent = Intent(Settings.Panel.ACTION_WIFI).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            try {
                                val intent = Intent(Settings.ACTION_WIFI_SETTINGS).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                result.success(true)
                            } catch (_: Exception) {
                                result.success(false)
                            }
                        }
                    }
                    "toggleFlashlight" -> {
                        val enable = call.argument<Boolean>("enable") ?: false
                        try {
                            val cm = getSystemService(CAMERA_SERVICE) as CameraManager
                            val id = cm.cameraIdList.firstOrNull { cid ->
                                cm.getCameraCharacteristics(cid).get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
                            }
                            if (id != null) {
                                cm.setTorchMode(id, enable)
                                result.success(true)
                            } else {
                                result.success(false)
                            }
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "setSpeakerphone" -> {
                        val enable = call.argument<Boolean>("enable") ?: false
                        val am = getSystemService(AUDIO_SERVICE) as AudioManager
                        am.isSpeakerphoneOn = enable
                        result.success(true)
                    }
                    "setBrightness" -> {
                        // Note: requires WRITE_SETTINGS permission (user must grant in settings)
                        try {
                            val level = call.argument<Int>("level") ?: 128
                            android.provider.Settings.System.putInt(
                                contentResolver,
                                android.provider.Settings.System.SCREEN_BRIGHTNESS,
                                (level * 255 / 100).coerceIn(0, 255)
                            )
                            result.success(true)
                        } catch (_: Exception) { result.success(false) }
                    }
                    "sendSMS" -> {
                        val num = call.argument<String>("number") ?: ""
                        val msg = call.argument<String>("message") ?: ""
                        if (num.isBlank() || msg.isBlank()) { result.success("ERROR: missing number or message"); return@setMethodCallHandler }
                        try {
                            val sms = android.telephony.SmsManager.getDefault()
                            sms.sendTextMessage(num, null, msg, null, null)
                            result.success("SUCCESS")
                        } catch (e: Exception) { result.success("ERROR: ${e.message}") }
                    }
                    "setAlarm" -> {
                        val hour   = call.argument<Int>("hour") ?: 7
                        val minute = call.argument<Int>("minute") ?: 0
                        val label  = call.argument<String>("label") ?: "Jack Alarm"
                        val i = Intent(android.provider.AlarmClock.ACTION_SET_ALARM).apply {
                            putExtra(android.provider.AlarmClock.EXTRA_HOUR, hour)
                            putExtra(android.provider.AlarmClock.EXTRA_MINUTES, minute)
                            putExtra(android.provider.AlarmClock.EXTRA_MESSAGE, label)
                            putExtra(android.provider.AlarmClock.EXTRA_SKIP_UI, true)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(i)
                        result.success("SUCCESS")
                    }
                    "setTimer" -> {
                        val seconds = call.argument<Int>("seconds") ?: 60
                        val label   = call.argument<String>("label") ?: "Jack Timer"
                        val i = Intent(android.provider.AlarmClock.ACTION_SET_TIMER).apply {
                            putExtra(android.provider.AlarmClock.EXTRA_LENGTH, seconds)
                            putExtra(android.provider.AlarmClock.EXTRA_MESSAGE, label)
                            putExtra(android.provider.AlarmClock.EXTRA_SKIP_UI, true)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(i)
                        result.success("SUCCESS")
                    }
                    "toggleBluetooth" -> {
                        val enable = call.argument<Boolean>("enable") ?: false
                        // On Android 13+, can only open settings; direct toggle needs BLUETOOTH_CONNECT
                        try {
                            @Suppress("DEPRECATION")
                            val bt = BluetoothAdapter.getDefaultAdapter()
                            if (bt != null) {
                                if (enable) bt.enable() else bt.disable()
                                result.success(true)
                            } else { result.success(false) }
                        } catch (_: Exception) {
                            startActivity(Intent(android.provider.Settings.ACTION_BLUETOOTH_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                            result.success(true)
                        }
                    }
                    "toggleFlashlight" -> {
                        val enable = call.argument<Boolean>("enable") ?: true
                        try {
                            val cm = getSystemService(CAMERA_SERVICE) as CameraManager
                            val cameraId = cm.cameraIdList[0]
                            cm.setTorchMode(cameraId, enable)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "openWifiSettings" -> {
                        try {
                            val intent = Intent(android.provider.Settings.ACTION_WIFI_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "takeScreenshot" -> {
                        val svc = JackAccessibilityService.instance
                        if (svc != null) {
                            svc.captureScreen { bytes ->
                                result.success(bytes != null)
                            }
                        } else {
                            result.success(false)
                        }
                    }
                    "openCamera" -> {
                        try {
                            val intent = Intent(android.provider.MediaStore.INTENT_ACTION_STILL_IMAGE_CAMERA).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "openBluetoothSettings" -> {
                        try {
                            val intent = Intent(android.provider.Settings.ACTION_BLUETOOTH_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "openSoundSettings" -> {
                        try {
                            val intent = Intent(android.provider.Settings.ACTION_SOUND_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "openDisplaySettings" -> {
                        try {
                            val intent = Intent(android.provider.Settings.ACTION_DISPLAY_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "openBatterySettings" -> {
                        try {
                            val intent = Intent(Intent.ACTION_POWER_USAGE_SUMMARY).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // ── Jack Master Controller Channel (Autonomous Screen Control) ────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.jack.agent/controller")
            .setMethodCallHandler { call, result ->
                val master = JackMasterAccessibilityService.instance
                val svc = JackAccessibilityService.instance
                when (call.method) {
                    "isAccessibilityActive" -> result.success(JackMasterAccessibilityService.isRunning() || svc != null)
                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                        result.success(true)
                    }
                    "openOverlaySettings" -> {
                        val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName")).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                    "openWriteSettings" -> {
                        val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS, Uri.parse("package:$packageName")).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                    "openNotificationListenerSettings" -> {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                    "openBatteryOptimizationSettings" -> {
                        val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                    "openAppSettings" -> {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                    "getRealDeviceMetrics" -> {
                        val batteryManager = getSystemService(BATTERY_SERVICE) as BatteryManager
                        val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager

                        val batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
                        val isCharging = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_STATUS) == BatteryManager.BATTERY_STATUS_CHARGING

                        val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
                        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                        val normalizedVolume = if (maxVolume > 0) ((currentVolume.toFloat() / maxVolume.toFloat()) * 100).toInt() else 0

                        val ringerMode = when (audioManager.ringerMode) {
                            AudioManager.RINGER_MODE_SILENT -> "SILENT"
                            AudioManager.RINGER_MODE_VIBRATE -> "VIBRATE"
                            else -> "NORMAL"
                        }

                        var brightness = 0
                        try {
                            brightness = Settings.System.getInt(contentResolver, Settings.System.SCREEN_BRIGHTNESS)
                        } catch (e: Exception) {}

                        result.success(mapOf(
                            "batteryLevel" to batteryLevel,
                            "isCharging" to isCharging,
                            "mediaVolume" to normalizedVolume,
                            "ringerMode" to ringerMode,
                            "brightness" to brightness
                        ))
                    }
                    "readScreen" -> {
                        if (master != null) {
                            result.success(master.dumpActiveScreenHierarchy())
                        } else if (svc != null) {
                            result.success(svc.getScreenText())
                        } else {
                            result.error("SERVICE_OFF", "No accessibility service running", null)
                        }
                    }
                    "clickNode" -> {
                        val id = call.argument<String>("id")
                        val text = call.argument<String>("text")
                        var ok = master?.clickTarget(id, text) == true
                        if (!ok && text != null && svc != null) {
                            ok = svc.performClickOnText(text)
                        }
                        result.success(ok)
                    }
                    "clickCoords" -> {
                        val x = call.argument<Double>("x")?.toFloat() ?: 0f
                        val y = call.argument<Double>("y")?.toFloat() ?: 0f
                        var handled = false
                        if (master != null) {
                            master.clickCoordinates(x, y)
                            handled = true
                        } else if (svc != null) {
                            handled = svc.clickCoordinates(x, y)
                        }
                        if (!handled && JackShizukuManager.isAvailable() && JackShizukuManager.hasPermission()) {
                            lifecycleScope.launch {
                                JackShizukuManager.tap(x, y)
                            }
                            handled = true
                        }
                        result.success(handled)
                    }
                    "typeText" -> {
                        val data = call.argument<String>("data") ?: ""
                        val id = call.argument<String>("id")
                        val text = call.argument<String>("text")
                        var ok = master?.typeIntoTarget(id, text, data) == true
                        if (!ok && svc != null) {
                            ok = svc.performTypeText(data)
                        }
                        if (!ok && JackShizukuManager.isAvailable() && JackShizukuManager.hasPermission()) {
                            lifecycleScope.launch {
                                JackShizukuManager.typeText(data)
                            }
                            ok = true
                        }
                        result.success(ok)
                    }
                    "swipe" -> {
                        val startX = call.argument<Double>("startX")?.toFloat() ?: 540f
                        val startY = call.argument<Double>("startY")?.toFloat() ?: 1600f
                        val endX = call.argument<Double>("endX")?.toFloat() ?: 540f
                        val endY = call.argument<Double>("endY")?.toFloat() ?: 400f
                        val duration = call.argument<Int>("duration")?.toLong() ?: 300L
                        var handled = false
                        if (master != null) {
                            master.performSwipe(startX, startY, endX, endY, duration)
                            handled = true
                        } else if (svc != null) {
                            val path = android.graphics.Path().apply {
                                moveTo(startX, startY)
                                lineTo(endX, endY)
                            }
                            val stroke = android.accessibilityservice.GestureDescription.StrokeDescription(path, 0, duration)
                            handled = svc.dispatchGesture(android.accessibilityservice.GestureDescription.Builder().addStroke(stroke).build(), null, null)
                        }
                        if (!handled && JackShizukuManager.isAvailable() && JackShizukuManager.hasPermission()) {
                            lifecycleScope.launch {
                                JackShizukuManager.swipe(startX, startY, endX, endY, duration)
                            }
                            handled = true
                        }
                        result.success(handled)
                    }
                    "globalAction" -> {
                        val actionStr = call.argument<String>("action") ?: ""
                        val code = when (actionStr) {
                            "BACK" -> A11ySvc.GLOBAL_ACTION_BACK
                            "HOME" -> A11ySvc.GLOBAL_ACTION_HOME
                            "RECENTS" -> A11ySvc.GLOBAL_ACTION_RECENTS
                            "NOTIFICATIONS" -> A11ySvc.GLOBAL_ACTION_NOTIFICATIONS
                            "QUICK_SETTINGS" -> A11ySvc.GLOBAL_ACTION_QUICK_SETTINGS
                            "SCREENSHOT" -> A11ySvc.GLOBAL_ACTION_TAKE_SCREENSHOT
                            "LOCK_SCREEN" -> A11ySvc.GLOBAL_ACTION_LOCK_SCREEN
                            "POWER_DIALOG" -> A11ySvc.GLOBAL_ACTION_POWER_DIALOG
                            else -> -1
                        }
                        var ok = if (code != -1 && master != null) master.executeGlobal(code) else false
                        if (!ok && code != -1 && svc != null) {
                            ok = svc.performGlobalAction(code)
                        }
                        result.success(ok)
                    }
                    "toggleFlashlight" -> {
                        val enable = call.argument<Boolean>("enable") ?: false
                        try {
                            val cm = getSystemService(CAMERA_SERVICE) as CameraManager
                            val id = cm.cameraIdList.firstOrNull { cid ->
                                cm.getCameraCharacteristics(cid).get(android.hardware.camera2.CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
                            }
                            if (id != null) { cm.setTorchMode(id, enable); result.success(enable) }
                            else result.error("NO_FLASH", "No flash unit", null)
                        } catch (e: Exception) { result.error("TORCH_FAIL", e.message, null) }
                    }
                    else -> result.notImplemented()
                }
            }

        // ── Shizuku ADB Shell Channel ─────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHIZUKU_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkStatus" -> result.success(
                        mapOf(
                            "available"     to JackShizukuManager.isAvailable(),
                            "hasPermission" to JackShizukuManager.hasPermission()
                        )
                    )
                    "requestPermission" -> {
                        JackShizukuManager.requestPermission()
                        result.success(true)
                    }
                    "execTap" -> {
                        val x = call.argument<Double>("x")?.toFloat() ?: 0f
                        val y = call.argument<Double>("y")?.toFloat() ?: 0f
                        lifecycleScope.launch {
                            JackShizukuManager.tap(x, y)
                                .onSuccess { result.success(true) }
                                .onFailure { result.error("SHZ_FAIL", it.message, null) }
                        }
                    }
                    "execSwipe" -> {
                        val x1  = call.argument<Double>("x1")?.toFloat() ?: 0f
                        val y1  = call.argument<Double>("y1")?.toFloat() ?: 0f
                        val x2  = call.argument<Double>("x2")?.toFloat() ?: 0f
                        val y2  = call.argument<Double>("y2")?.toFloat() ?: 0f
                        val dur = call.argument<Int>("duration")?.toLong() ?: 300L
                        lifecycleScope.launch {
                            JackShizukuManager.swipe(x1, y1, x2, y2, dur)
                                .onSuccess { result.success(true) }
                                .onFailure { result.error("SHZ_FAIL", it.message, null) }
                        }
                    }
                    "execText" -> {
                        val text = call.argument<String>("text") ?: ""
                        lifecycleScope.launch {
                            JackShizukuManager.typeText(text)
                                .onSuccess { result.success(true) }
                                .onFailure { result.error("SHZ_FAIL", it.message, null) }
                        }
                    }
                    "execRaw" -> {
                        val cmd = call.argument<String>("cmd") ?: ""
                        lifecycleScope.launch {
                            JackShizukuManager.exec(cmd)
                                .onSuccess { result.success(it) }
                                .onFailure { result.error("SHZ_FAIL", it.message, null) }
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // ── Overlay / Glow Channel ────────────────────────────────────────────
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OVERLAY_CHANNEL)
        overlayChannel = channel
        channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermission" -> {
                        var fullyGranted = true
                        
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !android.provider.Settings.canDrawOverlays(this)) {
                            fullyGranted = false
                            startActivity(Intent(android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION, android.net.Uri.parse("package:$packageName")))
                        }
                        
                        if (!isAccessibilityServiceEnabled()) {
                            fullyGranted = false
                            startActivity(Intent(android.provider.Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        }
                        
                        if (!isNotificationListenerEnabled()) {
                            fullyGranted = false
                            startActivity(Intent(android.provider.Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        }
                        
                        // Request all required runtime permissions
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            requestPermissions(arrayOf(
                                android.Manifest.permission.CALL_PHONE,
                                android.Manifest.permission.READ_CONTACTS,
                                android.Manifest.permission.SEND_SMS,
                                android.Manifest.permission.READ_SMS,
                                android.Manifest.permission.READ_PHONE_STATE,
                                android.Manifest.permission.READ_CALENDAR,
                                android.Manifest.permission.PROCESS_OUTGOING_CALLS
                            ), 101)
                        }

                        result.success(fullyGranted)
                    }
                    "hasPermission" -> {
                        val has = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                            Settings.canDrawOverlays(this) else true
                        result.success(has)
                    }
                    "show" -> {
                        val mode = call.argument<String>("mode") ?: JackOverlayService.MODE_LISTENING
                        if (JackOverlayService.instance != null) {
                            JackOverlayService.instance!!.updateMode(mode)
                            if (mode == "bubble") {
                                JackOverlayService.instance!!.showBubble()
                            } else {
                                JackOverlayService.instance!!.showPill()
                            }
                        } else {
                            val i = Intent(this, JackOverlayService::class.java)
                            i.putExtra(JackOverlayService.EXTRA_MODE, mode)
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                                startForegroundService(i) else startService(i)
                        }
                        result.success(true)
                    }
                    "hide" -> {
                        stopService(Intent(this, JackOverlayService::class.java))
                        result.success(true)
                    }
                    "updateOverlayChat" -> {
                        val user = call.argument<String>("user") ?: call.argument<String>("text") ?: ""
                        val jack = call.argument<String>("jack") ?: ""
                        JackOverlayService.instance?.updateChatText(user, jack)
                        result.success(true)
                    }
                    "updateAudioLevel" -> {
                        val level = call.argument<Double>("level")?.toFloat() ?: 0f
                        JackOverlayService.instance?.updateAudioLevel(level)
                        result.success(true)
                    }
                    "expandOverlay" -> {
                        JackOverlayService.instance?.expandOverlay()
                        result.success(true)
                    }
                    "collapseOverlay" -> {
                        JackOverlayService.instance?.collapseOverlay()
                        result.success(true)
                    }
                    "showBubble" -> {
                        JackOverlayService.instance?.showBubble()
                        result.success(true)
                    }
                    "hideAll" -> {
                        JackOverlayService.instance?.hideAll()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // ── Notifications Channel ──────────────────────────────────────────────
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIF_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    JackNotificationListener.onNotification = { title, text, pkg ->
                        events?.success(mapOf("title" to title, "text" to text, "pkg" to pkg))
                    }
                }
                override fun onCancel(arguments: Any?) {
                    JackNotificationListener.onNotification = null
                }
            })

        // ── Call Events Channel ─────────────────────────────────────────────
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CALL_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    JackCallReceiver.callEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    JackCallReceiver.callEventSink = null
                }
            })
    }

    private fun resolveContactNumber(name: String): String? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && checkSelfPermission(android.Manifest.permission.READ_CONTACTS) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
            return null
        }
        val uri = ContactsContract.CommonDataKinds.Phone.CONTENT_URI
        val projection = arrayOf(ContactsContract.CommonDataKinds.Phone.NUMBER)
        val selection = "${ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME} LIKE ?"
        val selectionArgs = arrayOf("%$name%")
        var number: String? = null
        contentResolver.query(uri, projection, selection, selectionArgs, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                number = cursor.getString(0)
            }
        }
        return number
    }
    override fun onDestroy() {
        callTts?.stop()
        callTts?.shutdown()
        super.onDestroy()
    }
}
