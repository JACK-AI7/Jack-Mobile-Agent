package com.syncra.syncra.service

import android.content.pm.PackageManager
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import rikka.shizuku.Shizuku
import java.io.BufferedReader
import java.io.InputStreamReader

/**
 * JackShizukuManager
 *
 * Provides privileged ADB-shell-level on-device automation via the Shizuku API.
 * Shizuku runs a background process with UID 2000 (com.android.shell) — equivalent
 * to USB-ADB commands but entirely on the phone with zero PC/cable dependency.
 *
 * Prerequisites (one-time, done by user):
 *   1. Install Shizuku from Google Play / GitHub.
 *   2. Enable Wireless Debugging in Developer Options.
 *   3. Start Shizuku via Wireless Debugging pairing.
 *   4. Approve "Allow Jack" when the dialog appears.
 */
object JackShizukuManager {
    private const val TAG            = "JackShizuku"
    private const val SHIZUKU_REQ    = 8001

    @Volatile private var isBinderAlive = false

    private val onBinderReceived = Shizuku.OnBinderReceivedListener {
        isBinderAlive = true
        Log.i(TAG, "Shizuku Binder alive — ping: ${Shizuku.pingBinder()}")
    }

    private val onBinderDead = Shizuku.OnBinderDeadListener {
        isBinderAlive = false
        Log.w(TAG, "Shizuku Binder died")
    }

    private val onPermResult = Shizuku.OnRequestPermissionResultListener { code, grant ->
        if (code == SHIZUKU_REQ) Log.i(TAG, "Shizuku permission: ${grant == PackageManager.PERMISSION_GRANTED}")
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    fun initialize() {
        Shizuku.addBinderReceivedListenerSticky(onBinderReceived)
        Shizuku.addBinderDeadListener(onBinderDead)
        Shizuku.addRequestPermissionResultListener(onPermResult)
    }

    // ── Status ────────────────────────────────────────────────────────────────

    fun isAvailable(): Boolean = try {
        isBinderAlive && Shizuku.pingBinder()
    } catch (_: Exception) { false }

    fun hasPermission(): Boolean = try {
        isAvailable() && Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED
    } catch (_: Exception) { false }

    fun requestPermission() {
        if (isAvailable() && !hasPermission()) {
            Shizuku.requestPermission(SHIZUKU_REQ)
        }
    }

    // ── Core: Execute arbitrary ADB shell command ─────────────────────────────

    /**
     * Spawns a privileged shell process (UID 2000 = com.android.shell) via
     * Shizuku.newProcess — equivalent to: adb shell <command>
     */
    suspend fun exec(command: String): Result<String> = withContext(Dispatchers.IO) {
        if (!hasPermission()) {
            return@withContext Result.failure(
                IllegalStateException("Shizuku permission not granted — user must approve Jack in the Shizuku dialog")
            )
        }
        return@withContext try {
            val newProcessMethod = Shizuku::class.java.getDeclaredMethod(
                "newProcess",
                Array<String>::class.java,
                Array<String>::class.java,
                String::class.java
            ).apply { isAccessible = true }

            val proc = newProcessMethod.invoke(
                null,
                arrayOf("sh", "-c", command),
                null,
                null
            ) as java.lang.Process

            val stdout = BufferedReader(InputStreamReader(proc.inputStream)).readText()
            val stderr = BufferedReader(InputStreamReader(proc.errorStream)).readText()
            val exit   = proc.waitFor()
            if (exit == 0) {
                Result.success(stdout.trim())
            } else {
                Result.failure(RuntimeException("Exit $exit — stderr: ${stderr.trim()}"))
            }
        } catch (e: Exception) {
            Log.e(TAG, "exec failed: ${e.message}")
            Result.failure(e)
        }
    }

    // ── High-level automation wrappers ────────────────────────────────────────

    /** ADB tap: input tap x y */
    suspend fun tap(x: Float, y: Float) = exec("input tap $x $y")

    /** ADB swipe: input swipe x1 y1 x2 y2 durationMs */
    suspend fun swipe(x1: Float, y1: Float, x2: Float, y2: Float, durationMs: Long = 300) =
        exec("input swipe $x1 $y1 $x2 $y2 $durationMs")

    /**
     * ADB text injection: input text 'hello world'
     * Escapes spaces as %s (required by Android input subsystem).
     */
    suspend fun typeText(text: String): Result<String> {
        val shell = text
            .replace("\\", "\\\\")
            .replace("'", "\\'")
            .replace(" ", "%s")
        return exec("input text '$shell'")
    }

    /** ADB key event: input keyevent <keyCode> */
    suspend fun keyEvent(keyCode: Int) = exec("input keyevent $keyCode")

    /** Scroll up via ADB swipe (default screen center) */
    suspend fun scrollUp(screenW: Float = 1080f, screenH: Float = 2340f) =
        swipe(screenW / 2, screenH * 0.7f, screenW / 2, screenH * 0.3f)

    /** Scroll down via ADB swipe */
    suspend fun scrollDown(screenW: Float = 1080f, screenH: Float = 2340f) =
        swipe(screenW / 2, screenH * 0.3f, screenW / 2, screenH * 0.7f)

    /** ADB screenshot: screencap /sdcard/jack_shot.png */
    suspend fun screenshot(): Result<String> =
        exec("screencap -p /sdcard/Pictures/jack_screenshot_${System.currentTimeMillis()}.png")
}
