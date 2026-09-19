package com.syncra.syncra.service

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.graphics.Rect
import android.os.Bundle
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import org.json.JSONArray
import org.json.JSONObject
import java.util.ArrayDeque

/**
 * Jack Master Accessibility Service
 *
 * High-privilege autonomous screen automation engine:
 *   - FLAG_RETRIEVE_INTERACTIVE_WINDOWS → sees any open window including overlays
 *   - canPerformGestures="true"         → injects touch, swipe, and tap gestures
 *   - canRetrieveWindowContent="true"   → reads full UI node hierarchy
 *
 * Exposed to Flutter via com.jack.agent/controller MethodChannel in MainActivity.
 */
class JackMasterAccessibilityService : AccessibilityService() {

    companion object {
        @Volatile var instance: JackMasterAccessibilityService? = null
            private set

        fun isRunning(): Boolean = instance != null
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        android.util.Log.d("JackMaster", "JackMasterAccessibilityService connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Available for reactive automation triggers if needed
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        super.onDestroy()
        instance = null
    }

    // ── Vision Engine: Dump Active Screen ────────────────────────────────────

    /**
     * Serialises the active window's UI tree as JSON.
     * Returns: { "nodes": [ { id, text, clickable, bounds: {left,top,right,bottom,centerX,centerY} } ] }
     */
    fun dumpActiveScreenHierarchy(): String {
        val rootNode = rootInActiveWindow ?: return "{\"nodes\":[]}"
        val rootJson = JSONObject()
        val nodesArray = JSONArray()

        val queue = ArrayDeque<AccessibilityNodeInfo>()
        queue.add(rootNode)

        while (queue.isNotEmpty()) {
            val node = queue.poll() ?: continue
            val bounds = Rect()
            node.getBoundsInScreen(bounds)

            val text = node.text?.toString()
                ?: node.contentDescription?.toString()
            val resId = node.viewIdResourceName

            if (!text.isNullOrBlank() || !resId.isNullOrBlank() || node.isClickable) {
                nodesArray.put(JSONObject().apply {
                    put("id", resId ?: "")
                    put("text", text ?: "")
                    put("clickable", node.isClickable)
                    put("bounds", JSONObject().apply {
                        put("left",    bounds.left)
                        put("top",     bounds.top)
                        put("right",   bounds.right)
                        put("bottom",  bounds.bottom)
                        put("centerX", bounds.centerX())
                        put("centerY", bounds.centerY())
                    })
                })
            }

            for (i in 0 until node.childCount) {
                node.getChild(i)?.let { queue.add(it) }
            }
        }

        rootJson.put("nodes", nodesArray)
        return rootJson.toString()
    }

    // ── Action Engine: Click ──────────────────────────────────────────────────

    /**
     * Finds and clicks the node matching [resourceId] or [queryText].
     * Walks up to the nearest clickable ancestor if the found node itself
     * is not clickable (e.g., a label inside a button).
     */
    fun clickTarget(resourceId: String?, queryText: String?): Boolean {
        val root = rootInActiveWindow ?: return false
        val targetNode = searchHierarchy(root, resourceId, queryText) ?: return false

        var actionable: AccessibilityNodeInfo? = targetNode
        while (actionable != null && !actionable.isClickable) {
            actionable = actionable.parent
        }

        return if (actionable != null) {
            val result = actionable.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            actionable.recycle()
            result
        } else {
            val b = Rect()
            targetNode.getBoundsInScreen(b)
            clickCoordinates(b.centerX().toFloat(), b.centerY().toFloat())
            true
        }
    }

    // ── Action Engine: Type Text ──────────────────────────────────────────────

    /**
     * Injects [textToType] into the editable field matching [resourceId] or [queryText].
     */
    fun typeIntoTarget(
        resourceId: String?,
        queryText: String?,
        textToType: String,
    ): Boolean {
        val root = rootInActiveWindow ?: return false
        val targetNode = searchHierarchy(root, resourceId, queryText) ?: return false

        var inputNode: AccessibilityNodeInfo? = targetNode
        while (inputNode != null && !inputNode.isEditable && !inputNode.isFocusable) {
            inputNode = inputNode.parent
        }

        return if (inputNode != null) {
            inputNode.performAction(AccessibilityNodeInfo.ACTION_FOCUS)
            val bundle = Bundle().apply {
                putCharSequence(
                    AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE,
                    textToType,
                )
            }
            val success = inputNode.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, bundle)
            inputNode.recycle()
            success
        } else {
            false
        }
    }

    // ── Action Engine: Gestures ───────────────────────────────────────────────

    /** Synthesises a tap gesture at absolute screen coordinates. */
    fun clickCoordinates(x: Float, y: Float) {
        val path = Path().apply { moveTo(x, y) }
        val stroke = GestureDescription.StrokeDescription(path, 0L, 50L)
        dispatchGesture(GestureDescription.Builder().addStroke(stroke).build(), null, null)
    }

    /** Synthesises a directional swipe gesture. */
    fun performSwipe(
        startX: Float,
        startY: Float,
        endX: Float,
        endY: Float,
        durationMs: Long,
    ) {
        val path = Path().apply {
            moveTo(startX, startY)
            lineTo(endX, endY)
        }
        val stroke = GestureDescription.StrokeDescription(path, 0L, durationMs.coerceAtLeast(100L))
        dispatchGesture(GestureDescription.Builder().addStroke(stroke).build(), null, null)
    }

    // ── Action Engine: Global System Actions ─────────────────────────────────

    /** Fires a global Android accessibility action (HOME, BACK, SCREENSHOT, etc.). */
    fun executeGlobal(actionCode: Int): Boolean = performGlobalAction(actionCode)

    // ── Private: BFS Node Search ─────────────────────────────────────────────

    private fun searchHierarchy(
        root: AccessibilityNodeInfo,
        resourceId: String?,
        queryText: String?,
    ): AccessibilityNodeInfo? {
        val queue = ArrayDeque<AccessibilityNodeInfo>()
        queue.add(root)

        while (queue.isNotEmpty()) {
            val current = queue.poll() ?: continue

            val matchId = !resourceId.isNullOrBlank() &&
                current.viewIdResourceName?.contains(resourceId, ignoreCase = true) == true

            val matchText = !queryText.isNullOrBlank() && (
                current.text?.toString()?.contains(queryText, ignoreCase = true) == true ||
                current.contentDescription?.toString()
                    ?.contains(queryText, ignoreCase = true) == true
            )

            if (matchId || matchText) {
                queue.forEach { it.recycle() }
                return current
            }

            for (i in 0 until current.childCount) {
                current.getChild(i)?.let { queue.add(it) }
            }
        }
        return null
    }
}
