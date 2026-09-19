package com.syncra.syncra.service

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.util.Log

/**
 * JackAutonomousExecutor — Tier-Cascading Action Engine
 *
 * Implements the 3-tier cascading strategy:
 *   Tier 1  Semantic  — Android AccessibilityService node match (zero latency)
 *   Tier 2  Coordinate — Gesture to screen coordinates (Accessibility or Shizuku)
 *   Tier 3  Shell     — Shizuku ADB input commands (max compatibility)
 *
 * All action methods are suspend-safe and dispatched from coroutine scope.
 */
class JackAutonomousExecutor(private val context: Context) {

    companion object { private const val TAG = "JackExecutor" }

    fun executeAction(actionType: String, textQuery: String?, x: Float?, y: Float?) {
        val a11y = JackMasterAccessibilityService.instance

        when (actionType.uppercase()) {
            "CLICK" -> {
                // Tier 1: Attempt direct semantic match via Accessibility
                val success = if (!textQuery.isNullOrBlank()) {
                    a11y?.clickTarget(resourceId = null, queryText = textQuery) ?: false
                } else false

                // Tier 2: Fallback to coordinate tap if semantic search fails
                if (!success && x != null && y != null) {
                    a11y?.clickCoordinates(x, y)
                }
            }

            "INPUT_TEXT" -> {
                a11y?.typeIntoTarget(resourceId = null, queryText = textQuery, textToType = textQuery ?: "")
            }

            "GLOBAL_NAV" -> {
                // BACK = 1, HOME = 2, RECENTS = 3
                a11y?.executeGlobal(AccessibilityService.GLOBAL_ACTION_BACK)
            }
        }
    }

    // ── CLICK ─────────────────────────────────────────────────────────────────

    /**
     * Clicks a UI element matching [textQuery] or absolute coordinates ([x], [y]).
     *
     * Cascade:
     *   1. Accessibility semantic click (text/ID match via BFS)
     *   2. Accessibility coordinate tap
     *   3. Shizuku `input tap x y` (if Shizuku is available)
     */
    suspend fun click(textQuery: String? = null, x: Float? = null, y: Float? = null) {
        val a11y = JackMasterAccessibilityService.instance

        // Tier 1 — Semantic accessibility click
        val semanticHit = if (!textQuery.isNullOrBlank() && a11y != null) {
            val result = a11y.clickTarget(resourceId = null, queryText = textQuery)
            Log.d(TAG, "Tier1 semantic '$textQuery': $result")
            result
        } else false

        if (semanticHit) return

        // Tier 2 — Coordinate gesture (Accessibility)
        if (x != null && y != null && a11y != null) {
            Log.d(TAG, "Tier2 coord tap ($x,$y)")
            a11y.clickCoordinates(x, y)
            return
        }

        // Tier 3 — Shizuku ADB shell tap (fallback)
        if (x != null && y != null && JackShizukuManager.isAvailable() && JackShizukuManager.hasPermission()) {
            Log.d(TAG, "Tier3 Shizuku tap ($x,$y)")
            JackShizukuManager.tap(x, y)
        } else {
            Log.w(TAG, "All tiers failed — no coordinate or service available")
        }
    }

    // ── TYPE TEXT ─────────────────────────────────────────────────────────────

    /**
     * Types [text] into the field matching [targetQuery].
     *
     * Cascade:
     *   1. Accessibility ACTION_SET_TEXT on matching node
     *   2. Shizuku `input text`
     */
    suspend fun type(text: String, targetQuery: String? = null) {
        val a11y = JackMasterAccessibilityService.instance

        if (!targetQuery.isNullOrBlank() && a11y != null) {
            val ok = a11y.typeIntoTarget(null, targetQuery, text)
            if (ok) { Log.d(TAG, "Tier1 type OK"); return }
        }

        // Shizuku fallback
        if (JackShizukuManager.hasPermission()) {
            Log.d(TAG, "Tier3 Shizuku type")
            JackShizukuManager.typeText(text)
        }
    }

    // ── SWIPE ─────────────────────────────────────────────────────────────────

    /** Swipe between two screen points. Uses Accessibility → Shizuku cascade. */
    suspend fun swipe(x1: Float, y1: Float, x2: Float, y2: Float, durationMs: Long = 300) {
        val a11y = JackMasterAccessibilityService.instance
        if (a11y != null) {
            a11y.performSwipe(x1, y1, x2, y2, durationMs)
        } else if (JackShizukuManager.hasPermission()) {
            JackShizukuManager.swipe(x1, y1, x2, y2, durationMs)
        }
    }

    // ── GLOBAL ACTIONS ────────────────────────────────────────────────────────

    /**
     * Triggers a named global system action.
     * Falls back to Shizuku keyevent if AccessibilityService is not bound.
     */
    fun globalAction(actionName: String) {
        val a11y = JackMasterAccessibilityService.instance
        val code = when (actionName.uppercase()) {
            "BACK"           -> AccessibilityService.GLOBAL_ACTION_BACK
            "HOME"           -> AccessibilityService.GLOBAL_ACTION_HOME
            "RECENTS"        -> AccessibilityService.GLOBAL_ACTION_RECENTS
            "NOTIFICATIONS"  -> AccessibilityService.GLOBAL_ACTION_NOTIFICATIONS
            "QUICK_SETTINGS" -> AccessibilityService.GLOBAL_ACTION_QUICK_SETTINGS
            "SCREENSHOT"     -> AccessibilityService.GLOBAL_ACTION_TAKE_SCREENSHOT
            "LOCK_SCREEN"    -> AccessibilityService.GLOBAL_ACTION_LOCK_SCREEN
            else             -> -1
        }
        if (code != -1 && a11y != null) a11y.executeGlobal(code)
    }

    // ── READ SCREEN ───────────────────────────────────────────────────────────

    /**
     * Returns the full active window UI tree as JSON.
     * Falls back to empty string if Accessibility Service is not bound.
     */
    fun readScreen(): String {
        return JackMasterAccessibilityService.instance?.dumpActiveScreenHierarchy() ?: "{\"nodes\":[]}"
    }
}
