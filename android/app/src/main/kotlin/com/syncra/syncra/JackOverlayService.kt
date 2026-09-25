package com.syncra.syncra

import android.animation.ValueAnimator
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.*
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.text.TextUtils
import android.util.TypedValue
import android.view.*
import android.view.animation.LinearInterpolator
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat

/**
 * JackOverlayService — Native Floating 3D Jack Orb & Gemini Live Horizontal Bar
 *
 * Behaviour:
 *   • Real 3D Jack Orb (76 dp) with volumetric gradients, glowing twin capsule eyes, and ambient bloom.
 *   • Appears ONLY outside of the app (on home screen or over other apps).
 *   • Completely movable / draggable anywhere on screen without jitter or drift.
 *   • Click / Tap → Expands smoothly into the Gemini Live horizontal bottom pill.
 *   • Pill shows live user speech transcript, animated Jack audio waveform, and Jack's voice reply.
 *   • Tap pill to collapse back into the 3D Jack Orb.
 */
class JackOverlayService : Service() {

    companion object {
        const val EXTRA_MODE  = "mode"
        const val MODE_LISTENING = "listening"
        const val MODE_THINKING  = "thinking"
        const val MODE_EXECUTING = "executing"
        const val MODE_SPEAKING  = "speaking"
        const val CHANNEL_ID  = "jack_overlay"
        const val NOTIF_ID    = 9001

        var instance: JackOverlayService? = null
    }

    private var windowManager: WindowManager? = null
    private var bubbleView: JackBubbleView? = null
    private var pillView: JackPillView? = null
    private var bubbleParams: WindowManager.LayoutParams? = null
    private var pillParams: WindowManager.LayoutParams? = null
    private var currentMode = MODE_LISTENING
    private var pillVisible = false

    // ── Service lifecycle ──────────────────────────────────────────────────────

    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()
        startForeground(NOTIF_ID, buildNotification())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val mode = intent?.getStringExtra(EXTRA_MODE) ?: MODE_LISTENING
        currentMode = mode
        if (bubbleView == null) initViews()
        bubbleView?.setMode(mode)
        pillView?.setMode(mode)
        return START_STICKY
    }

    override fun onDestroy() {
        instance = null
        removeAll()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // ── Build views ────────────────────────────────────────────────────────────

    private fun initViews() {
        if (!Settings.canDrawOverlays(this)) return

        val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        windowManager = wm

        val overlayType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_SYSTEM_ALERT

        val metrics = resources.displayMetrics
        val sw = metrics.widthPixels
        val sh = metrics.heightPixels

        // ── 1. Real 3D Jack Orb Bubble (Collapsed state) ─────────────────────
        val bubble = JackBubbleView(this)
        bubble.setMode(currentMode)
        bubbleView = bubble

        val bSize = dpToPx(76)
        val bp = WindowManager.LayoutParams(
            bSize, bSize, overlayType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = sw - bSize - dpToPx(20)
            y = sh - bSize - dpToPx(130)
        }
        bubbleParams = bp

        // Smooth Dragging anywhere on screen + Tap to Expand
        var initialX = 0
        var initialY = 0
        var touchStartX = 0f
        var touchStartY = 0f
        var isDragging = false

        bubble.setOnTouchListener { _, ev ->
            when (ev.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = bp.x
                    initialY = bp.y
                    touchStartX = ev.rawX
                    touchStartY = ev.rawY
                    isDragging = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = ev.rawX - touchStartX
                    val dy = ev.rawY - touchStartY
                    if (Math.hypot(dx.toDouble(), dy.toDouble()) > dpToPx(8)) {
                        isDragging = true
                    }
                    if (isDragging) {
                        bp.x = (initialX + dx).toInt().coerceIn(0, sw - bSize)
                        bp.y = (initialY + dy).toInt().coerceIn(0, sh - bSize)
                        windowManager?.updateViewLayout(bubble, bp)
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (!isDragging) {
                        // Tap! Expand to Gemini Live horizontal pill and start listening
                        showPill()
                        MainActivity.triggerJackListen()
                    } else {
                        windowManager?.updateViewLayout(bubble, bp)
                    }
                    true
                }
                else -> false
            }
        }

        wm.addView(bubble, bp)

        // ── 2. Gemini Live Horizontal Bottom Pill (Expanded state) ────────────
        val pill = JackPillView(this)
        pill.setMode(currentMode)
        pill.visibility = View.GONE
        pillView = pill

        val pp = WindowManager.LayoutParams(
            sw - dpToPx(32),
            WindowManager.LayoutParams.WRAP_CONTENT,
            overlayType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
            y = dpToPx(24)
        }
        pillParams = pp

        var startY = 0f
        pill.setOnTouchListener { _, ev ->
            when (ev.action) {
                MotionEvent.ACTION_DOWN -> {
                    startY = ev.rawY
                    true
                }
                MotionEvent.ACTION_UP -> {
                    val dy = ev.rawY - startY
                    if (dy > dpToPx(40)) {
                        // Swiped down: dismiss pill cleanly
                        hidePill()
                        MainActivity.onPillClosed()
                    } else {
                        // Tapped pill: ensure listening is active
                        MainActivity.triggerJackListen()
                    }
                    true
                }
                else -> false
            }
        }

        wm.addView(pill, pp)
    }

    // ── Show / hide pill ───────────────────────────────────────────────────────

    fun showPill() {
        if (MainActivity.isForeground) return
        if (pillVisible) return
        pillVisible = true
        val pill = pillView ?: return
        post {
            pill.visibility = View.VISIBLE
            pill.animate().alpha(1f).scaleX(1f).scaleY(1f).setDuration(220).start()
            bubbleView?.animate()?.alpha(0f)?.setDuration(180)?.withEndAction {
                bubbleView?.visibility = View.GONE
            }?.start()
        }
    }

    fun hidePill() {
        if (!pillVisible) return
        pillVisible = false
        val pill = pillView ?: return
        post {
            pill.animate().alpha(0f).scaleX(0.85f).scaleY(0.85f).setDuration(200)
                .withEndAction { pill.visibility = View.GONE }.start()
            bubbleView?.visibility = View.VISIBLE
            bubbleView?.animate()?.alpha(1f)?.setDuration(200)?.start()
        }
    }

    private fun post(action: () -> Unit) {
        pillView?.post(action) ?: bubbleView?.post(action)
    }

    // ── Public API called from Flutter / MethodChannel ─────────────────────────

    fun expandOverlay() {
        if (MainActivity.isForeground) return
        if (bubbleView == null) initViews()
        showPill()
    }

    fun collapseOverlay() = hidePill()

    fun updateMode(mode: String) {
        currentMode = mode
        bubbleView?.setMode(mode)
        pillView?.setMode(mode)
    }

    fun updateChatText(user: String, jack: String) {
        pillView?.setChatText(user, jack)
    }

    fun updateAudioLevel(level: Float) {
        bubbleView?.setAudioLevel(level)
        pillView?.setAudioLevel(level)
    }

    fun showBubble() {
        if (MainActivity.isForeground) {
            hideAll()
            return
        }
        if (bubbleView == null) initViews()
        bubbleView?.visibility = View.VISIBLE
        bubbleView?.alpha = 1f
        pillView?.visibility = View.GONE
        pillVisible = false
    }

    fun hideAll() {
        bubbleView?.visibility = View.GONE
        pillView?.visibility = View.GONE
        pillVisible = false
    }

    // ── Remove all views ───────────────────────────────────────────────────────

    private fun removeAll() {
        try { bubbleView?.let { windowManager?.removeViewImmediate(it) } } catch (_: Exception) {}
        try { pillView?.let { windowManager?.removeViewImmediate(it) } } catch (_: Exception) {}
        bubbleView = null; pillView = null; windowManager = null
    }

    // ── Notification ───────────────────────────────────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val chan = NotificationChannel(
                CHANNEL_ID, "Jack Active", NotificationManager.IMPORTANCE_LOW
            ).apply { setShowBadge(false); description = "Jack AI agent is running" }
            (getSystemService(NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(chan)
        }
    }

    private fun buildNotification(): Notification =
        NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Jack is active")
            .setContentText("Tap the 3D Orb to talk")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setOngoing(true).setSilent(true).build()

    private fun dpToPx(dp: Int) =
        (dp * resources.displayMetrics.density).toInt()
}

// ─────────────────────────────────────────────────────────────────────────────
// JackBubbleView — The Real 3D Jack Orb (Draggable, glowing, twin capsule eyes)
// ─────────────────────────────────────────────────────────────────────────────
class JackBubbleView(context: Context) : View(context) {

    private val ambientPinkPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
        color = Color.parseColor("#EC4899")
        maskFilter = BlurMaskFilter(24f, BlurMaskFilter.Blur.NORMAL)
    }
    private val ambientPeachPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
        color = Color.parseColor("#FFD166")
        maskFilter = BlurMaskFilter(20f, BlurMaskFilter.Blur.NORMAL)
    }
    private val ambientCyanPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
        color = Color.parseColor("#00E5FF")
        maskFilter = BlurMaskFilter(24f, BlurMaskFilter.Blur.NORMAL)
    }

    private val spherePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
    private val domePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
    private val rimPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 3f
    }

    private val eyeGlowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
        color = Color.parseColor("#00E5FF")
        maskFilter = BlurMaskFilter(12f, BlurMaskFilter.Blur.NORMAL)
    }
    private val eyeCorePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
        color = Color.WHITE
    }

    private val breatheAnim = ValueAnimator.ofFloat(0.96f, 1.04f).apply {
        duration = 1600
        repeatMode = ValueAnimator.REVERSE
        repeatCount = ValueAnimator.INFINITE
        interpolator = LinearInterpolator()
        addUpdateListener { invalidate() }
    }

    private val eyeBlinkAnim = ValueAnimator.ofFloat(1.0f, 0.12f).apply {
        duration = 160
        repeatMode = ValueAnimator.REVERSE
        repeatCount = 1
        interpolator = LinearInterpolator()
        addUpdateListener { invalidate() }
    }

    private var audioNorm = 0f
    private var currentMode = JackOverlayService.MODE_LISTENING
    private var lastBlinkTime = System.currentTimeMillis()

    init {
        setWillNotDraw(false)
    }

    fun setMode(mode: String) {
        currentMode = mode
        val colorHex = when (mode) {
            JackOverlayService.MODE_THINKING -> "#7C3AED"
            JackOverlayService.MODE_EXECUTING -> "#38BDF8"
            JackOverlayService.MODE_SPEAKING -> "#EC4899"
            else -> "#00E5FF"
        }
        eyeGlowPaint.color = Color.parseColor(colorHex)
        invalidate()
    }

    fun setAudioLevel(level: Float) {
        audioNorm = ((level + 40f) / 50f).coerceIn(0f, 1f)
        invalidate()
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        breatheAnim.start()
    }

    override fun onDetachedFromWindow() {
        breatheAnim.cancel()
        eyeBlinkAnim.cancel()
        super.onDetachedFromWindow()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val w = width.toFloat()
        val h = height.toFloat()
        val cx = w / 2f
        val cy = h / 2f
        val baseRadius = minOf(cx, cy) * 0.72f
        val breathe = breatheAnim.animatedValue as Float
        val boost = 1f + audioNorm * 0.18f
        val radius = baseRadius * breathe * boost

        // Random blink check every ~4 seconds
        val now = System.currentTimeMillis()
        if (now - lastBlinkTime > 3800 && !eyeBlinkAnim.isRunning) {
            lastBlinkTime = now
            eyeBlinkAnim.start()
        }

        // ── 1. Ambient Bloom Glows ──────────────────────────────────────────
        ambientPinkPaint.alpha = (90 * boost).toInt().coerceIn(30, 150)
        canvas.drawCircle(cx - radius * 0.35f, cy - radius * 0.1f, radius * 0.85f, ambientPinkPaint)

        ambientPeachPaint.alpha = (75 * boost).toInt().coerceIn(20, 140)
        canvas.drawCircle(cx - radius * 0.30f, cy + radius * 0.45f, radius * 0.70f, ambientPeachPaint)

        ambientCyanPaint.alpha = (100 * boost).toInt().coerceIn(30, 160)
        canvas.drawCircle(cx + radius * 0.35f, cy, radius * 0.85f, ambientCyanPaint)

        // ── 2. Volumetric 3D Celestial Plasma Sphere ─────────────────────────
        val spherePath = Path().apply {
            addCircle(cx, cy, radius, Path.Direction.CW)
        }
        canvas.save()
        canvas.clipPath(spherePath)

        // Layer A: Celestial Flow Gradient
        val celestialShader = LinearGradient(
            cx - radius, cy - radius * 0.3f,
            cx + radius, cy + radius * 0.3f,
            intArrayOf(
                Color.parseColor("#F472B6"), // Soft pink
                Color.parseColor("#E879F9"), // Lilac
                Color.parseColor("#818CF8"), // Indigo
                Color.parseColor("#38BDF8"), // Sky blue
                Color.parseColor("#00E5FF")  // Cyan
            ),
            floatArrayOf(0.0f, 0.25f, 0.50f, 0.75f, 1.0f),
            Shader.TileMode.CLAMP
        )
        spherePaint.shader = celestialShader
        canvas.drawCircle(cx, cy, radius, spherePaint)

        // Layer B: Radiant Cyan Dome (Right)
        val cyanDome = RadialGradient(
            cx + radius * 0.45f, cy - radius * 0.05f, radius * 0.85f,
            intArrayOf(Color.parseColor("#F000E5FF"), Color.parseColor("#800284C7"), Color.TRANSPARENT),
            floatArrayOf(0.0f, 0.55f, 1.0f),
            Shader.TileMode.CLAMP
        )
        domePaint.shader = cyanDome
        canvas.drawCircle(cx, cy, radius, domePaint)

        // Layer C: Vibrant Magenta Core (Left)
        val magentaCore = RadialGradient(
            cx - radius * 0.45f, cy - radius * 0.15f, radius * 0.90f,
            intArrayOf(Color.parseColor("#F0EC4899"), Color.parseColor("#80A855F7"), Color.TRANSPARENT),
            floatArrayOf(0.0f, 0.58f, 1.0f),
            Shader.TileMode.CLAMP
        )
        domePaint.shader = magentaCore
        canvas.drawCircle(cx, cy, radius, domePaint)

        // Layer D: Warm Sunrise Peach Glow (Bottom-Left)
        val peachGlow = RadialGradient(
            cx - radius * 0.50f, cy + radius * 0.50f, radius * 0.70f,
            intArrayOf(Color.parseColor("#E0FFD166"), Color.parseColor("#60FB923C"), Color.TRANSPARENT),
            floatArrayOf(0.0f, 0.50f, 1.0f),
            Shader.TileMode.CLAMP
        )
        domePaint.shader = peachGlow
        canvas.drawCircle(cx, cy, radius, domePaint)

        // Layer E: Deep Indigo Center Core
        val depthCore = RadialGradient(
            cx, cy, radius * 0.60f,
            intArrayOf(Color.parseColor("#403B82F6"), Color.parseColor("#301E1B4B"), Color.TRANSPARENT),
            floatArrayOf(0.0f, 0.55f, 1.0f),
            Shader.TileMode.CLAMP
        )
        domePaint.shader = depthCore
        canvas.drawCircle(cx, cy, radius, domePaint)

        canvas.restore()

        // ── 3. Luminous Outer Rim Light ──────────────────────────────────────
        val rimShader = SweepGradient(
            cx, cy,
            intArrayOf(
                Color.parseColor("#00E5FF"),
                Color.parseColor("#38BDF8"),
                Color.parseColor("#FFD166"),
                Color.parseColor("#EC4899"),
                Color.parseColor("#E879F9"),
                Color.parseColor("#00E5FF")
            ),
            null
        )
        val rimMat = Matrix().apply { postRotate((now % 4000) / 11.11f, cx, cy) }
        rimShader.setLocalMatrix(rimMat)
        rimPaint.shader = rimShader
        rimPaint.strokeWidth = 2.4f
        rimPaint.alpha = 220
        canvas.drawCircle(cx, cy, radius - 1.2f, rimPaint)

        // ── 4. Glowing Twin Capsule Eyes ─────────────────────────────────────
        val eyeScaleY = if (eyeBlinkAnim.isRunning) eyeBlinkAnim.animatedValue as Float else 1.0f
        val eyeH = radius * 0.38f * eyeScaleY
        val eyeW = radius * 0.12f
        val eyeSpacing = radius * 0.28f
        val eyeR = eyeW / 2f

        val leftEye = RectF(
            cx - eyeSpacing / 2f - eyeW / 2f,
            cy - eyeH / 2f,
            cx - eyeSpacing / 2f + eyeW / 2f,
            cy + eyeH / 2f
        )
        val rightEye = RectF(
            cx + eyeSpacing / 2f - eyeW / 2f,
            cy - eyeH / 2f,
            cx + eyeSpacing / 2f + eyeW / 2f,
            cy + eyeH / 2f
        )

        // Diffuse Eye Glow
        eyeGlowPaint.alpha = (140 * boost).toInt().coerceIn(60, 220)
        canvas.drawRoundRect(leftEye, eyeR, eyeR, eyeGlowPaint)
        canvas.drawRoundRect(rightEye, eyeR, eyeR, eyeGlowPaint)

        // Solid White Capsule Fill
        eyeCorePaint.alpha = 245
        canvas.drawRoundRect(leftEye, eyeR, eyeR, eyeCorePaint)
        canvas.drawRoundRect(rightEye, eyeR, eyeR, eyeCorePaint)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// JackPillView — The Expanded Gemini Live Horizontal Bottom Pill
// ─────────────────────────────────────────────────────────────────────────────
class JackPillView(context: Context) : FrameLayout(context) {

    private val userLabel: TextView
    private val jackLabel: TextView
    private val waveView: JackWaveView
    private val glowBorderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 3f
        maskFilter = BlurMaskFilter(16f, BlurMaskFilter.Blur.NORMAL)
    }
    private var modeColors = intArrayOf(Color.parseColor("#7C3AED"), Color.parseColor("#00E5FF"))
    private var audioNorm = 0f

    init {
        val bg = GradientDrawable().apply {
            setColor(Color.parseColor("#E60D0D14")) // Dark premium glassmorphism
            cornerRadius = dpToPx(28).toFloat()
            setStroke(dpToPx(1), Color.parseColor("#33FFFFFF"))
        }
        background = bg
        elevation = 16f
        setPadding(dpToPx(18), dpToPx(14), dpToPx(18), dpToPx(14))
        setWillNotDraw(false)
        clipToPadding = false
        clipChildren = false

        val inner = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
        }

        // Header: Jack Agent indicator
        val headerRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, 0, 0, dpToPx(6))
        }

        val dot = View(context).apply {
            layoutParams = LinearLayout.LayoutParams(dpToPx(8), dpToPx(8)).apply {
                marginEnd = dpToPx(6)
            }
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#00E5FF"))
            }
        }
        headerRow.addView(dot)

        val title = TextView(context).apply {
            text = "JACK LIVE"
            setTextColor(Color.parseColor("#CC00E5FF"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
            typeface = Typeface.create("sans-serif-medium", Typeface.BOLD)
            letterSpacing = 0.16f
        }
        headerRow.addView(title)

        val spacer = View(context).apply {
            layoutParams = LinearLayout.LayoutParams(0, 1, 1f)
        }
        headerRow.addView(spacer)

        val closeBtn = TextView(context).apply {
            text = "✕"
            setTextColor(Color.parseColor("#99FFFFFF"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            setPadding(dpToPx(8), dpToPx(2), dpToPx(4), dpToPx(2))
            setOnClickListener {
                (context as? JackOverlayService)?.let { svc ->
                    svc.hidePill()
                    MainActivity.onPillClosed()
                }
            }
        }
        headerRow.addView(closeBtn)
        inner.addView(headerRow)

        // Gemini-Style Audio Waveform (5 animated bars in Jack colors)
        waveView = JackWaveView(context)
        inner.addView(waveView, LayoutParams(LayoutParams.MATCH_PARENT, dpToPx(42)))

        // User speech transcript (Gemini Live sleek single-line query)
        userLabel = TextView(context).apply {
            text = "Listening..."
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14.5f)
            typeface = Typeface.create("sans-serif", Typeface.NORMAL)
            gravity = Gravity.CENTER
            maxLines = 1
            ellipsize = TextUtils.TruncateAt.END
            setPadding(0, dpToPx(4), 0, 0)
            inner.addView(this)
        }

        // Jack's verbal answer transcript (Compact 2-line clean spoken preview)
        jackLabel = TextView(context).apply {
            text = ""
            setTextColor(Color.parseColor("#CC00E5FF"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            gravity = Gravity.CENTER
            maxLines = 2
            ellipsize = TextUtils.TruncateAt.END
            setPadding(0, dpToPx(3), 0, 0)
            inner.addView(this)
        }

        addView(inner)
        alpha = 0f
        scaleX = 0.88f
        scaleY = 0.88f
    }

    fun setMode(mode: String) {
        modeColors = when (mode) {
            JackOverlayService.MODE_LISTENING -> intArrayOf(Color.parseColor("#7C3AED"), Color.parseColor("#00E5FF"))
            JackOverlayService.MODE_THINKING  -> intArrayOf(Color.parseColor("#EC4899"), Color.parseColor("#7C3AED"))
            JackOverlayService.MODE_EXECUTING -> intArrayOf(Color.parseColor("#00E5FF"), Color.parseColor("#FFD166"))
            JackOverlayService.MODE_SPEAKING  -> intArrayOf(Color.parseColor("#00E5FF"), Color.parseColor("#EC4899"))
            else -> intArrayOf(Color.parseColor("#7C3AED"), Color.parseColor("#00E5FF"))
        }
        val modeText = when (mode) {
            JackOverlayService.MODE_LISTENING -> "Listening..."
            JackOverlayService.MODE_THINKING  -> "Thinking..."
            JackOverlayService.MODE_EXECUTING -> "Executing hardware..."
            JackOverlayService.MODE_SPEAKING  -> "Speaking..."
            else -> "Listening..."
        }
        post { userLabel.text = modeText }
        waveView.setMode(mode)
        invalidate()
    }

    fun setChatText(user: String, jack: String) {
        post {
            if (user.isNotEmpty()) {
                val cleanUser = user.replace("\n", " ").trim()
                userLabel.text = cleanUser
            }
            if (jack.isNotEmpty()) {
                // Strip markdown, URLs, headers, bullet points, brackets to guarantee clean spoken preview
                var cleanJack = jack
                    .replace(Regex("""!\[.*?\]\(.*?\)""", RegexOption.DOT_MATCHES_ALL), "")
                    .replace(Regex("""\[(.*?)\]\((https?://\S+)\)"""), "$1")
                    .replace(Regex("""https?://\S+"""), "")
                    .replace(Regex("""[#*`_>~]"""), "")
                    .replace(Regex("""\s+"""), " ")
                    .trim()
                if (cleanJack.length > 140) {
                    cleanJack = cleanJack.substring(0, 137) + "..."
                }
                jackLabel.text = cleanJack
            }
        }
    }

    fun setAudioLevel(level: Float) {
        audioNorm = ((level + 40f) / 50f).coerceIn(0f, 1f)
        waveView.setAudioLevel(audioNorm)
        invalidate()
    }

    override fun dispatchDraw(canvas: Canvas) {
        super.dispatchDraw(canvas)

        val w = width.toFloat()
        val h = height.toFloat()
        val cornerR = dpToPx(28).toFloat()
        val inset = glowBorderPaint.strokeWidth / 2f

        val sweepColors = intArrayOf(modeColors[0], modeColors[1], modeColors[0], modeColors[1], modeColors[0])
        val sweepShader = SweepGradient(w / 2f, h / 2f, sweepColors, null)
        val mat = Matrix().apply { postRotate((System.currentTimeMillis() % 3600) / 10f, w / 2f, h / 2f) }
        sweepShader.setLocalMatrix(mat)
        glowBorderPaint.shader = sweepShader
        glowBorderPaint.strokeWidth = 3f + audioNorm * 4f
        glowBorderPaint.alpha = 200

        canvas.drawRoundRect(
            RectF(inset, inset, w - inset, h - inset),
            cornerR, cornerR, glowBorderPaint
        )
    }

    private fun dpToPx(dp: Int) = (dp * resources.displayMetrics.density).toInt()
}

// ─────────────────────────────────────────────────────────────────────────────
// JackWaveView — Gemini-Style Animated Waveform (5 bars with Jack color palette)
// ─────────────────────────────────────────────────────────────────────────────
class JackWaveView(context: Context) : View(context) {

    private val bars = 5
    private val animators = Array(bars) { idx ->
        ValueAnimator.ofFloat(0.2f, 1.0f).apply {
            duration = (450 + idx * 110).toLong()
            repeatMode = ValueAnimator.REVERSE
            repeatCount = ValueAnimator.INFINITE
            startDelay = (idx * 70).toLong()
            interpolator = LinearInterpolator()
            addUpdateListener { invalidate() }
        }
    }
    private val barPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
    private var barColors = intArrayOf(
        Color.parseColor("#EC4899"), // Neon pink
        Color.parseColor("#E879F9"), // Lilac
        Color.parseColor("#818CF8"), // Indigo
        Color.parseColor("#38BDF8"), // Sky blue
        Color.parseColor("#00E5FF")  // Cyan
    )
    private var audioMult = 1f

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        animators.forEach { it.start() }
    }

    override fun onDetachedFromWindow() {
        animators.forEach { it.cancel() }
        super.onDetachedFromWindow()
    }

    fun setMode(mode: String) {
        barColors = when (mode) {
            JackOverlayService.MODE_LISTENING -> intArrayOf(
                Color.parseColor("#EC4899"), Color.parseColor("#E879F9"), Color.parseColor("#818CF8"), Color.parseColor("#38BDF8"), Color.parseColor("#00E5FF")
            )
            JackOverlayService.MODE_THINKING -> intArrayOf(
                Color.parseColor("#7C3AED"), Color.parseColor("#A855F7"), Color.parseColor("#EC4899"), Color.parseColor("#A855F7"), Color.parseColor("#7C3AED")
            )
            JackOverlayService.MODE_EXECUTING -> intArrayOf(
                Color.parseColor("#00E5FF"), Color.parseColor("#38BDF8"), Color.parseColor("#FFD166"), Color.parseColor("#38BDF8"), Color.parseColor("#00E5FF")
            )
            JackOverlayService.MODE_SPEAKING -> intArrayOf(
                Color.parseColor("#00E5FF"), Color.parseColor("#34D399"), Color.parseColor("#10B981"), Color.parseColor("#34D399"), Color.parseColor("#00E5FF")
            )
            else -> intArrayOf(
                Color.parseColor("#EC4899"), Color.parseColor("#E879F9"), Color.parseColor("#818CF8"), Color.parseColor("#38BDF8"), Color.parseColor("#00E5FF")
            )
        }
    }

    fun setAudioLevel(norm: Float) {
        audioMult = 0.35f + norm * 0.65f
    }

    override fun onDraw(canvas: Canvas) {
        val w = width.toFloat()
        val h = height.toFloat()
        val barW = dpToPx(6).toFloat()
        val cx = w / 2f
        val spacing = dpToPx(10).toFloat()
        val totalWidth = barW * bars + spacing * (bars - 1)
        val startX = cx - totalWidth / 2f

        for (i in 0 until bars) {
            val scale = (animators[i].animatedValue as Float) * audioMult
            val barH = (h * 0.85f * scale).coerceAtLeast(dpToPx(6).toFloat())
            val x = startX + i * (barW + spacing)
            barPaint.color = barColors[i]
            barPaint.alpha = (235 * scale).toInt().coerceIn(80, 255)
            val top = (h - barH) / 2f
            canvas.drawRoundRect(x, top, x + barW, top + barH, barW / 2f, barW / 2f, barPaint)
        }
    }

    private fun dpToPx(dp: Int) = (dp * resources.displayMetrics.density).toInt()
}
