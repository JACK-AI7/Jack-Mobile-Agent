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
    }

    private val DOM_CHANNEL     = "com.syncra.syncra/accessibility"
    private val OVERLAY_CHANNEL = "com.syncra.syncra/overlay"
    private val NOTIF_CHANNEL   = "com.syncra.syncra/notifications"
    private val CALL_CHANNEL    = "com.syncra.syncra/calls"
    private val CALL_TALK_CHANNEL = "com.syncra.syncra/call_talk"
    private val SHIZUKU_CHANNEL = "com.jack.agent/shizuku"

    private var callTts: TextToSpeech? = null
    private var shizukuInitialized = false

    // Hide bubble when the Jack app itself is open
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
        JackOverlayService.instance?.showBubble()
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expected = "$packageName/${JackAccessibilityService::class.java.name}"
        val enabledServices = android.provider.Settings.Secure.getString(
            contentResolver, android.provider.Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        val colonSplitter = android.text.TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(enabledServices)
        while (colonSplitter.hasNext()) {
            if (colonSplitter.next().equals(expected, ignoreCase = true)) {
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

        // Init Call Talk TTS engine
        callTts = TextToSpeech(this) { status ->
            if (status == TextToSpeech.SUCCESS) {
                callTts?.setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build()
                )
            }
        }

        // ── Call Talk Channel ───────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALL_TALK_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "speak" -> {
                        val text = call.argument<String>("text") ?: ""
                        val lang = call.argument<String>("lang") ?: "en"
                        callTts?.language = Locale(lang)
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
                        am.setStreamVolume(AudioManager.STREAM_MUSIC, (level * max / 100), 0)
                        result.success(true)
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
                when (call.method) {
                    "isAccessibilityActive" -> result.success(JackMasterAccessibilityService.isRunning())
                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
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
                        if (master != null) result.success(master.dumpActiveScreenHierarchy())
                        else result.error("SERVICE_OFF", "JackMasterAccessibilityService not running", null)
                    }
                    "clickNode" -> {
                        val id = call.argument<String>("id")
                        val text = call.argument<String>("text")
                        if (master != null) result.success(master.clickTarget(id, text))
                        else result.error("SERVICE_OFF", "JackMasterAccessibilityService not running", null)
                    }
                    "clickCoords" -> {
                        master?.clickCoordinates(call.argument<Double>("x")?.toFloat() ?: 0f, call.argument<Double>("y")?.toFloat() ?: 0f)
                        result.success(true)
                    }
                    "typeText" -> {
                        result.success(master?.typeIntoTarget(call.argument("id"), call.argument("text"), call.argument<String>("data") ?: "") ?: false)
                    }
                    "swipe" -> {
                        master?.performSwipe(
                            call.argument<Double>("startX")?.toFloat() ?: 0f,
                            call.argument<Double>("startY")?.toFloat() ?: 0f,
                            call.argument<Double>("endX")?.toFloat() ?: 0f,
                            call.argument<Double>("endY")?.toFloat() ?: 0f,
                            call.argument<Int>("duration")?.toLong() ?: 300L
                        )
                        result.success(true)
                    }
                    "globalAction" -> {
                        val code = when (call.argument<String>("action") ?: "") {
                            "BACK" -> A11ySvc.GLOBAL_ACTION_BACK
                            "HOME" -> A11ySvc.GLOBAL_ACTION_HOME
                            "RECENTS" -> A11ySvc.GLOBAL_ACTION_RECENTS
                            "NOTIFICATIONS" -> A11ySvc.GLOBAL_ACTION_NOTIFICATIONS
                            "QUICK_SETTINGS" -> A11ySvc.GLOBAL_ACTION_QUICK_SETTINGS
                            "SCREENSHOT" -> A11ySvc.GLOBAL_ACTION_TAKE_SCREENSHOT
                            "LOCK_SCREEN" -> A11ySvc.GLOBAL_ACTION_LOCK_SCREEN
                            else -> -1
                        }
                        result.success(if (code != -1 && master != null) master.executeGlobal(code) else false)
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
