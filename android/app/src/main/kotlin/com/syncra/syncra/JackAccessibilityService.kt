package com.syncra.syncra

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Intent
import android.graphics.Path
import android.graphics.Rect
import android.os.Build
import android.os.Bundle
import android.view.ViewConfiguration
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityWindowInfo

class JackAccessibilityService : AccessibilityService() {

    companion object {
        var instance: JackAccessibilityService? = null
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        // Auto-Skip YouTube Ads
        if (event.packageName == "com.google.android.youtube") {
            val root = rootInActiveWindow
            if (root != null) {
                val skipNodes = root.findAccessibilityNodeInfosByText("Skip ad")
                if (!skipNodes.isNullOrEmpty()) {
                    skipNodes.firstOrNull()?.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                } else {
                    val skipNodes2 = root.findAccessibilityNodeInfosByText("Skip")
                    if (!skipNodes2.isNullOrEmpty()) {
                        skipNodes2.firstOrNull()?.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                    }
                }
            }
        }
    }

    override fun onInterrupt() {}

    override fun onUnbind(intent: Intent?): Boolean {
        instance = null
        return super.onUnbind(intent)
    }

    // ── CLICK by text (with multi-strategy fallback) ──────────────────────────

    fun performClickOnText(text: String): Boolean {
        val root = rootInActiveWindow ?: return false

        // Strategy 1: find by visible text
        var nodes = root.findAccessibilityNodeInfosByText(text)

        // Strategy 2: find by content description (for icon-only buttons)
        if (nodes.isNullOrEmpty()) {
            nodes = findByContentDescription(root, text)
        }

        // Strategy 3: find by view ID substring
        if (nodes.isNullOrEmpty()) {
            nodes = findByViewId(root, text)
        }

        for (node in nodes) {
            val clicked = clickNode(node)
            if (clicked) return true
        }

        // Strategy 4: tap by coordinates if text found anywhere on screen
        return tapCenterOfText(root, text)
    }

    private fun clickNode(node: AccessibilityNodeInfo): Boolean {
        if (node.isClickable) {
            node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            return true
        }
        // Walk up to find clickable parent
        var parent = node.parent
        var depth = 0
        while (parent != null && depth < 6) {
            if (parent.isClickable) {
                parent.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                return true
            }
            parent = parent.parent
            depth++
        }
        // Last resort: dispatch a gesture tap at the node's center
        val bounds = Rect()
        node.getBoundsInScreen(bounds)
        if (!bounds.isEmpty) {
            return tapAt(bounds.centerX().toFloat(), bounds.centerY().toFloat())
        }
        return false
    }

    private fun findByContentDescription(root: AccessibilityNodeInfo, desc: String): List<AccessibilityNodeInfo> {
        val results = mutableListOf<AccessibilityNodeInfo>()
        traverseTree(root) { node ->
            val cd = node.contentDescription?.toString() ?: ""
            if (cd.contains(desc, ignoreCase = true)) results.add(node)
        }
        return results
    }

    private fun findByViewId(root: AccessibilityNodeInfo, id: String): List<AccessibilityNodeInfo> {
        val results = mutableListOf<AccessibilityNodeInfo>()
        traverseTree(root) { node ->
            val vid = node.viewIdResourceName ?: ""
            if (vid.contains(id, ignoreCase = true)) results.add(node)
        }
        return results
    }

    private fun tapCenterOfText(root: AccessibilityNodeInfo, text: String): Boolean {
        var found = false
        traverseTree(root) { node ->
            if (!found) {
                val nodeText = node.text?.toString() ?: ""
                val nodeDesc = node.contentDescription?.toString() ?: ""
                if (nodeText.contains(text, ignoreCase = true) || nodeDesc.contains(text, ignoreCase = true)) {
                    val bounds = Rect()
                    node.getBoundsInScreen(bounds)
                    if (!bounds.isEmpty) {
                        found = tapAt(bounds.centerX().toFloat(), bounds.centerY().toFloat())
                    }
                }
            }
        }
        return found
    }

    // ── LONG PRESS by text ────────────────────────────────────────────────────

    fun performLongPressOnText(text: String): Boolean {
        val root = rootInActiveWindow ?: return false
        val nodes = root.findAccessibilityNodeInfosByText(text)
        for (node in nodes) {
            if (node.isLongClickable) {
                node.performAction(AccessibilityNodeInfo.ACTION_LONG_CLICK)
                return true
            }
            val bounds = Rect()
            node.getBoundsInScreen(bounds)
            if (!bounds.isEmpty) {
                return longPressAt(bounds.centerX().toFloat(), bounds.centerY().toFloat())
            }
        }
        return false
    }

    // ── TYPE TEXT into focused or first editable field ────────────────────────

    fun performTypeText(text: String): Boolean {
        val root = rootInActiveWindow ?: return false

        // First try to find focused editable
        var target: AccessibilityNodeInfo? = null
        traverseTree(root) { node ->
            if (target == null && node.isEditable) {
                target = node
                node.performAction(AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS)
            }
        }

        if (target == null) return false

        val args = Bundle()
        args.putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text)
        return target!!.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
    }

    // ── PRESS ENTER action ─────────────────────────────────────────────────────

    fun performPressEnter(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val root = rootInActiveWindow ?: return false
            var target: AccessibilityNodeInfo? = null
            traverseTree(root) { node ->
                if (target == null && node.isEditable && node.isFocused) {
                    target = node
                }
            }
            // fallback to first editable if none focused
            if (target == null) {
                traverseTree(root) { node ->
                    if (target == null && node.isEditable) target = node
                }
            }
            if (target != null) {
                return target!!.performAction(AccessibilityNodeInfo.AccessibilityAction.ACTION_IME_ENTER.id)
            }
        }
        return false
    }

    // ── SCROLL actions ─────────────────────────────────────────────────────────

    fun performScrollForward(): Boolean {
        val root = rootInActiveWindow ?: return swipeGesture(0.5f, 0.75f, 0.5f, 0.25f)
        // Try native scroll on scrollable views first
        var scrolled = false
        traverseTree(root) { node ->
            if (!scrolled && node.isScrollable) {
                scrolled = node.performAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD)
            }
        }
        return if (scrolled) true else swipeGesture(0.5f, 0.75f, 0.5f, 0.25f)
    }

    fun performScrollBackward(): Boolean {
        val root = rootInActiveWindow ?: return swipeGesture(0.5f, 0.25f, 0.5f, 0.75f)
        var scrolled = false
        traverseTree(root) { node ->
            if (!scrolled && node.isScrollable) {
                scrolled = node.performAction(AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD)
            }
        }
        return if (scrolled) true else swipeGesture(0.5f, 0.25f, 0.5f, 0.75f)
    }

    fun performSwipeUp() = swipeGesture(0.5f, 0.75f, 0.5f, 0.25f)
    fun performSwipeDown() = swipeGesture(0.5f, 0.25f, 0.5f, 0.75f)
    fun performSwipeLeft() = swipeGesture(0.85f, 0.5f, 0.15f, 0.5f)
    fun performSwipeRight() = swipeGesture(0.15f, 0.5f, 0.85f, 0.5f)

    // ── BACK / HOME / RECENTS ─────────────────────────────────────────────────

    fun performBack() = performGlobalAction(GLOBAL_ACTION_BACK)
    fun performHome() = performGlobalAction(GLOBAL_ACTION_HOME)
    fun performRecents() = performGlobalAction(GLOBAL_ACTION_RECENTS)
    fun performNotifications() = performGlobalAction(GLOBAL_ACTION_NOTIFICATIONS)
    fun performQuickSettings() = performGlobalAction(GLOBAL_ACTION_QUICK_SETTINGS)
    fun performLockScreen() = performGlobalAction(GLOBAL_ACTION_LOCK_SCREEN)

    // ── LAUNCH app by package ─────────────────────────────────────────────────

    fun performLaunchApp(packageName: String): Boolean {
        return try {
            val intent = packageManager.getLaunchIntentForPackage(packageName)
                ?: return false
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            applicationContext.startActivity(intent)
            true
        } catch (e: Exception) { false }
    }

    // ── GET current screen text (for context snapshotting) ────────────────────

    fun getScreenText(): String {
        val root = rootInActiveWindow ?: return ""
        val sb = StringBuilder()
        sb.append("<Screen>\n")
        dumpNode(root, sb, 1)
        sb.append("</Screen>")
        return sb.toString().take(6000) // limit size
    }

    private fun dumpNode(node: AccessibilityNodeInfo?, sb: StringBuilder, depth: Int) {
        if (node == null || depth > 12) return // prevent infinite loops or massive depth

        val className = node.className?.toString()?.substringAfterLast('.') ?: "View"
        val text = node.text?.toString()?.replace("\n", " ")?.replace("\"", "'") ?: ""
        val desc = node.contentDescription?.toString()?.replace("\n", " ")?.replace("\"", "'") ?: ""
        val clickable = node.isClickable
        val scrollable = node.isScrollable

        // Filter out empty layout containers to save tokens
        val isInteractive = clickable || scrollable
        val hasContent = text.isNotBlank() || desc.isNotBlank()
        
        if (!isInteractive && !hasContent) {
            // Skip this structural node in XML, but traverse its children
            for (i in 0 until node.childCount) {
                dumpNode(node.getChild(i), sb, depth)
            }
            return
        }

        val indent = "  ".repeat(depth)
        sb.append(indent).append("<").append(className)
        
        if (clickable) sb.append(" clickable=\"true\"")
        if (scrollable) sb.append(" scrollable=\"true\"")
        
        val content = if (text.isNotBlank()) text else desc
        if (content.isNotBlank()) {
            sb.append(" text=\"").append(content).append("\"")
        }
        
        val bounds = Rect()
        node.getBoundsInScreen(bounds)
        sb.append(" bounds=\"[${bounds.left},${bounds.top}][${bounds.right},${bounds.bottom}]\"")
        
        if (node.childCount == 0) {
            sb.append(" />\n")
        } else {
            sb.append(">\n")
            var hasValidChildren = false
            for (i in 0 until node.childCount) {
                val child = node.getChild(i)
                if (child != null) {
                    dumpNode(child, sb, depth + 1)
                    hasValidChildren = true
                }
            }
            if (hasValidChildren) {
                sb.append(indent)
            }
            sb.append("</").append(className).append(">\n")
        }
    }

    // ── Gesture helpers ───────────────────────────────────────────────────────

    private fun swipeGesture(fromXRatio: Float, fromYRatio: Float, toXRatio: Float, toYRatio: Float): Boolean {
        val metrics = resources.displayMetrics
        val w = metrics.widthPixels.toFloat()
        val h = metrics.heightPixels.toFloat()
        return tapPath(
            fromXRatio * w, fromYRatio * h,
            toXRatio * w, toYRatio * h,
            400L
        )
    }

    private fun tapAt(x: Float, y: Float): Boolean = tapPath(x, y, x, y, 50L)

    private fun longPressAt(x: Float, y: Float): Boolean = tapPath(x, y, x, y, 800L)

    private fun tapPath(fromX: Float, fromY: Float, toX: Float, toY: Float, duration: Long): Boolean {
        val path = Path()
        path.moveTo(fromX, fromY)
        path.lineTo(toX, toY)
        val stroke = GestureDescription.StrokeDescription(path, 0, duration)
        val builder = GestureDescription.Builder()
        builder.addStroke(stroke)
        return dispatchGesture(builder.build(), null, null)
    }

    // ── V27: Vision-Language Model Additions ────────────────────────────────

    fun clickCoordinates(x: Float, y: Float): Boolean {
        return tapAt(x, y)
    }

    fun captureScreen(callback: (ByteArray?) -> Unit) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            takeScreenshot(android.view.Display.DEFAULT_DISPLAY, applicationContext.mainExecutor, object : TakeScreenshotCallback {
                override fun onSuccess(screenshot: ScreenshotResult) {
                    val bitmap = android.graphics.Bitmap.wrapHardwareBuffer(screenshot.hardwareBuffer, screenshot.colorSpace)
                    val stream = java.io.ByteArrayOutputStream()
                    bitmap?.compress(android.graphics.Bitmap.CompressFormat.JPEG, 70, stream)
                    callback(stream.toByteArray())
                    bitmap?.recycle()
                }
                override fun onFailure(errorCode: Int) {
                    callback(null)
                }
            })
        } else {
            callback(null)
        }
    }

    // ── Tree traversal ────────────────────────────────────────────────────────

    private fun traverseTree(node: AccessibilityNodeInfo?, action: (AccessibilityNodeInfo) -> Unit) {
        if (node == null) return
        action(node)
        for (i in 0 until node.childCount) {
            traverseTree(node.getChild(i), action)
        }
    }
}
