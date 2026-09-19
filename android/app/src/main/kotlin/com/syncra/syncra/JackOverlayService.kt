package com.syncra.syncra

import android.animation.AnimatorSet
import android.animation.ObjectAnimator
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
import android.util.TypedValue
import android.view.*
import android.view.animation.LinearInterpolator
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat

/**
 * JackOverlayService — Gemini-style draggable floating bubble
 *
 * Behaviour:
 *   • Starts as a small glowing circle (72 dp) anchored bottom-right.
 *   • User can drag it anywhere on screen.
 *   • Tap → expands into a wide pill at the bottom of the screen.
 *   • Pill shows chat transcript + audio-reactive neon border.
 *   • Auto-hides when the Jack app is in foreground.
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

        // ── 1. Bubble (collapsed state) ──────────────────────────────────────
        val bubble = JackBubbleView(this)
        bubble.setMode(currentMode)
        bubbleView = bubble

        val bSize = dpToPx(70)
        val bp = WindowManager.LayoutParams(
            bSize, bSize, overlayType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = sw - bSize - dpToPx(16)      // Bottom-right (adjusted for y below)
            y = sh - bSize - dpToPx(120)
        }
        bubbleParams = bp

        // Touch: ONLY tap to expand (NO drag on bubble - it drifts)
        var iTx = 0f; var iTy = 0f
        bubble.setOnTouchListener { _, ev ->
            when (ev.action) {
                MotionEvent.ACTION_DOWN -> { iTx = ev.rawX; iTy = ev.rawY; true }
                MotionEvent.ACTION_UP -> {
                    val dist = Math.hypot((ev.rawX - iTx).toDouble(), (ev.rawY - iTy).toDouble())
                    if (dist < 18) {
                        // First move bubble to final position before showing pill
                        showPill()
                        MainActivity.triggerJackListen()
                    } else {
                        // Drag the bubble
                        bp.x = (bp.x + (ev.rawX - iTx)).toInt()
                        bp.y = (bp.y + (ev.rawY - iTy)).toInt()
                        windowManager?.updateViewLayout(bubble, bp)
                        iTx = ev.rawX; iTy = ev.rawY
                    }
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    bp.x = (bp.x + (ev.rawX - iTx)).toInt()
                    bp.y = (bp.y + (ev.rawY - iTy)).toInt()
                    windowManager?.updateViewLayout(bubble, bp)
                    iTx = ev.rawX; iTy = ev.rawY
                    true
                }
                else -> false
            }
        }

        wm.addView(bubble, bp)

        // ── 2. Pill (expanded state — hidden by default) ─────────────────────
        val pill = JackPillView(this)
        pill.setMode(currentMode)
        pill.visibility = View.GONE
        pillView = pill

        val pp = WindowManager.LayoutParams(
            sw - dpToPx(32), // Width slightly less than screen
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

        // Pill is FIXED at bottom — NO drag. Tap to collapse only.
        pill.setOnTouchListener { _, ev ->
            when (ev.action) {
                MotionEvent.ACTION_UP -> { hidePill(); true }
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

    // ── Public API called from Flutter ─────────────────────────────────────────

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
        pillView?.visibility = View.GONE
        pillVisible = false
    }

    fun hideAll() {
        bubbleView?.visibility = View.GONE
        pillView?.visibility = View.GONE
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
            .setContentText("Tap the bubble to talk")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setOngoing(true).setSilent(true).build()

    private fun dpToPx(dp: Int) =
        (dp * resources.displayMetrics.density).toInt()
}

// ─────────────────────────────────────────────────────────────────────────────
// JackBubbleView  — the small draggable circle
// ─────────────────────────────────────────────────────────────────────────────
class JackBubbleView(context: Context) : FrameLayout(context) {

    private val glowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
        maskFilter = BlurMaskFilter(28f, BlurMaskFilter.Blur.NORMAL)
    }
    private val corePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
    private val ringPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 3f
    }
    private var strandsView: View? = null

    init {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val sv = JackStrandsView(context)
            sv.layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
            strandsView = sv
            
            // Clip the bubble to a perfect circle so the strands don't spill into a square
            outlineProvider = object : ViewOutlineProvider() {
                override fun getOutline(view: View, outline: android.graphics.Outline) {
                    outline.setOval(0, 0, view.width, view.height)
                }
            }
            clipToOutline = true
            addView(sv, 0)
        }
    }

    private val pulseAnim = ValueAnimator.ofFloat(0.6f, 1.0f).apply {
        duration = 800; repeatMode = ValueAnimator.REVERSE
        repeatCount = ValueAnimator.INFINITE
        interpolator = LinearInterpolator()
        addUpdateListener { invalidate() }
    }

    private var audioNorm = 0f   // 0..1
    private var modeColors = intArrayOf(0xFF1B55FF.toInt(), 0xFF00F2FE.toInt())

    fun setMode(mode: String) {
        modeColors = when (mode) {
            JackOverlayService.MODE_LISTENING -> intArrayOf(0xFF1B55FF.toInt(), 0xFF00F2FE.toInt())
            JackOverlayService.MODE_THINKING  -> intArrayOf(0xFF7C4DFF.toInt(), 0xFF00E5FF.toInt())
            JackOverlayService.MODE_EXECUTING -> intArrayOf(0xFF00E5FF.toInt(), 0xFF1B55FF.toInt())
            JackOverlayService.MODE_SPEAKING  -> intArrayOf(0xFF00F2FE.toInt(), 0xFF3D5AFE.toInt())
            else -> intArrayOf(0xFF1B55FF.toInt(), 0xFF00F2FE.toInt())
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && strandsView is JackStrandsView) {
            (strandsView as JackStrandsView).setMode(mode)
        }
        invalidate()
    }

    fun setAudioLevel(level: Float) {
        audioNorm = ((level + 40f) / 50f).coerceIn(0f, 1f)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && strandsView is JackStrandsView) {
            (strandsView as JackStrandsView).setAudioLevel(audioNorm)
        }
    }

    override fun onAttachedToWindow() { super.onAttachedToWindow(); pulseAnim.start() }
    override fun onDetachedFromWindow() { pulseAnim.cancel(); super.onDetachedFromWindow() }

    override fun onDraw(canvas: Canvas) {
        val cx = width / 2f; val cy = height / 2f
        val r = minOf(cx, cy)
        val pulse = pulseAnim.animatedValue as Float
        val boost = 1f + audioNorm * 0.25f

        // Outer glow
        glowPaint.color = modeColors[0]
        glowPaint.alpha = (160 * pulse).toInt()
        canvas.drawCircle(cx, cy, r * 0.85f * boost, glowPaint)

        // Core gradient circle (only if strands are not present)
        if (strandsView == null) {
            val shader = RadialGradient(
                cx, cy, r * 0.72f,
                modeColors[0], modeColors[1], Shader.TileMode.CLAMP
            )
            corePaint.shader = shader
            corePaint.alpha = 255
            canvas.drawCircle(cx, cy, r * 0.72f, corePaint)
        }

        // White mic icon (simple circle inside)
        val iconPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE; style = Paint.Style.FILL; alpha = 220
        }
        // mic body
        canvas.drawRoundRect(
            cx - r * 0.16f, cy - r * 0.35f,
            cx + r * 0.16f, cy + r * 0.18f,
            r * 0.10f, r * 0.10f, iconPaint
        )
        // mic stand
        val ringP = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE; style = Paint.Style.STROKE; strokeWidth = r * 0.065f; alpha = 220
        }
        canvas.drawArc(
            cx - r * 0.28f, cy - r * 0.1f,
            cx + r * 0.28f, cy + r * 0.46f,
            180f, -180f, false, ringP
        )
        // stem line
        canvas.drawLine(cx, cy + r * 0.46f, cx, cy + r * 0.60f, ringP)
        canvas.drawLine(cx - r * 0.18f, cy + r * 0.60f, cx + r * 0.18f, cy + r * 0.60f, ringP)

        // Spinning neon ring — audio-reactive
        val ringRadius = r * 0.88f * boost
        val sweepShader = SweepGradient(cx, cy, modeColors + intArrayOf(modeColors[0]), null)
        val mat = Matrix()
        mat.postRotate((System.currentTimeMillis() % 3600) / 10f, cx, cy)
        sweepShader.setLocalMatrix(mat)
        ringPaint.shader = sweepShader
        ringPaint.strokeWidth = 3f + audioNorm * 5f
        ringPaint.alpha = (180 * pulse).toInt()
        canvas.drawCircle(cx, cy, ringRadius, ringPaint)
        // NOTE: pulseAnim ValueAnimator already calls invalidate() on each frame.
        // Do NOT call invalidate() here — it creates an unconditional 60fps GPU loop.
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// JackPillView  — the expanded bottom pill
// ─────────────────────────────────────────────────────────────────────────────
class JackPillView(context: Context) : FrameLayout(context) {

    private val userLabel: TextView
    private val jackLabel: TextView
    private val waveView: View
    private val glowBorderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE; strokeWidth = 4f
        maskFilter = BlurMaskFilter(20f, BlurMaskFilter.Blur.NORMAL)
    }
    private var modeColors = intArrayOf(0xFF9C27B0.toInt(), 0xFF5C6BC0.toInt())
    private var audioNorm = 0f

    init {
        val bg = GradientDrawable().apply {
            setColor(Color.parseColor("#CC0D0D14"))   // dark glass
            cornerRadius = dpToPx(32).toFloat()
        }
        background = bg
        elevation = 12f
        setPadding(dpToPx(20), dpToPx(16), dpToPx(20), dpToPx(16))
        setWillNotDraw(false)
        clipToPadding = false
        clipChildren = false

        val inner = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
        }

        // Jack label (top small)
        TextView(context).apply {
            text = "jack"
            setTextColor(Color.parseColor("#AA9C27B0"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            letterSpacing = 0.12f
            gravity = Gravity.CENTER
            inner.addView(this)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            waveView = JackStrandsView(context)
        } else {
            waveView = JackWaveView(context)
        }
        inner.addView(waveView, LayoutParams(LayoutParams.MATCH_PARENT, dpToPx(60)))

        userLabel = TextView(context).apply {
            text = "Listening..."
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            typeface = Typeface.create("sans-serif", Typeface.NORMAL)
            gravity = Gravity.CENTER
            setPadding(0, dpToPx(4), 0, 0)
            inner.addView(this)
        }

        jackLabel = TextView(context).apply {
            text = ""
            setTextColor(Color.parseColor("#CCFFFFFF"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            typeface = Typeface.create("sans-serif", Typeface.NORMAL)
            gravity = Gravity.CENTER
            setPadding(0, dpToPx(2), 0, 0)
            inner.addView(this)
        }

        addView(inner)
        alpha = 0f; scaleX = 0.85f; scaleY = 0.85f
    }

    fun setMode(mode: String) {
        modeColors = when (mode) {
            JackOverlayService.MODE_LISTENING -> intArrayOf(0xFF1B55FF.toInt(), 0xFF00F2FE.toInt())
            JackOverlayService.MODE_THINKING  -> intArrayOf(0xFF7C4DFF.toInt(), 0xFF00E5FF.toInt())
            JackOverlayService.MODE_EXECUTING -> intArrayOf(0xFF00E5FF.toInt(), 0xFF1B55FF.toInt())
            JackOverlayService.MODE_SPEAKING  -> intArrayOf(0xFF00F2FE.toInt(), 0xFF3D5AFE.toInt())
            else -> intArrayOf(0xFF1B55FF.toInt(), 0xFF00F2FE.toInt())
        }
        val modeText = when (mode) {
            JackOverlayService.MODE_LISTENING -> "Listening..."
            JackOverlayService.MODE_THINKING  -> "Thinking..."
            JackOverlayService.MODE_EXECUTING -> "Executing..."
            JackOverlayService.MODE_SPEAKING  -> "Speaking..."
            else -> "Listening..."
        }
        post { userLabel.text = modeText }
        if (waveView is JackWaveView) (waveView as JackWaveView).setMode(mode)
        else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && waveView is JackStrandsView) {
            (waveView as JackStrandsView).setMode(mode)
        }
        invalidate()
    }

    fun setChatText(user: String, jack: String) {
        post {
            if (user.isNotEmpty()) userLabel.text = user
            if (jack.isNotEmpty()) jackLabel.text = jack
        }
    }

    fun setAudioLevel(level: Float) {
        audioNorm = ((level + 40f) / 50f).coerceIn(0f, 1f)
        if (waveView is JackWaveView) (waveView as JackWaveView).setAudioLevel(audioNorm)
        else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && waveView is JackStrandsView) {
            (waveView as JackStrandsView).setAudioLevel(audioNorm)
        }
        invalidate()
    }

    override fun dispatchDraw(canvas: Canvas) {
        super.dispatchDraw(canvas)

        val w = width.toFloat(); val h = height.toFloat()
        val cornerR = dpToPx(32).toFloat()
        val inset = glowBorderPaint.strokeWidth / 2f

        val sweepColors = intArrayOf(modeColors[0], modeColors[1], modeColors[0], modeColors[1], modeColors[0])
        val sweepShader = SweepGradient(w / 2f, h / 2f, sweepColors, null)
        val mat = Matrix()
        mat.postRotate((System.currentTimeMillis() % 3600) / 10f, w / 2f, h / 2f)
        sweepShader.setLocalMatrix(mat)
        glowBorderPaint.shader = sweepShader
        glowBorderPaint.strokeWidth = 4f + audioNorm * 8f
        glowBorderPaint.alpha = 220

        canvas.drawRoundRect(
            RectF(inset, inset, w - inset, h - inset),
            cornerR, cornerR, glowBorderPaint
        )
        // NOTE: Border animation is driven by ValueAnimator — no manual invalidate needed here.
    }

    private fun dpToPx(dp: Int) = (dp * resources.displayMetrics.density).toInt()
}

// ─────────────────────────────────────────────────────────────────────────────
// JackWaveView  — Gemini-style animated wave bars inside the pill
// ─────────────────────────────────────────────────────────────────────────────
class JackWaveView(context: Context) : View(context) {

    private val bars = 5
    private val animators = Array(bars) {
        ValueAnimator.ofFloat(0.2f, 1.0f).apply {
            duration = (500 + it * 120).toLong()
            repeatMode = ValueAnimator.REVERSE
            repeatCount = ValueAnimator.INFINITE
            startDelay = (it * 80).toLong()
            interpolator = LinearInterpolator()
            addUpdateListener { invalidate() }
        }
    }
    private val barPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
    private var barColors = intArrayOf(0xFF9C27B0.toInt(), 0xFF7B1FA2.toInt(), 0xFF5C6BC0.toInt(), 0xFF7B1FA2.toInt(), 0xFF9C27B0.toInt())
    private var audioMult = 1f

    override fun onAttachedToWindow() { super.onAttachedToWindow(); animators.forEach { it.start() } }
    override fun onDetachedFromWindow() { animators.forEach { it.cancel() }; super.onDetachedFromWindow() }

    fun setMode(mode: String) {
        barColors = when (mode) {
            JackOverlayService.MODE_LISTENING -> intArrayOf(0xFF9C27B0.toInt(), 0xFF7B1FA2.toInt(), 0xFF5C6BC0.toInt(), 0xFF7B1FA2.toInt(), 0xFF9C27B0.toInt())
            JackOverlayService.MODE_THINKING  -> intArrayOf(0xFF00ACC1.toInt(), 0xFF006064.toInt(), 0xFF00897B.toInt(), 0xFF006064.toInt(), 0xFF00ACC1.toInt())
            JackOverlayService.MODE_EXECUTING -> intArrayOf(0xFFE53935.toInt(), 0xFFB71C1C.toInt(), 0xFFFB8C00.toInt(), 0xFFB71C1C.toInt(), 0xFFE53935.toInt())
            JackOverlayService.MODE_SPEAKING  -> intArrayOf(0xFF43A047.toInt(), 0xFF2E7D32.toInt(), 0xFF7CB342.toInt(), 0xFF2E7D32.toInt(), 0xFF43A047.toInt())
            else -> intArrayOf(0xFF9C27B0.toInt(), 0xFF7B1FA2.toInt(), 0xFF5C6BC0.toInt(), 0xFF7B1FA2.toInt(), 0xFF9C27B0.toInt())
        }
    }

    fun setAudioLevel(norm: Float) { audioMult = 0.3f + norm * 0.7f }

    override fun onDraw(canvas: Canvas) {
        val w = width.toFloat(); val h = height.toFloat()
        val barW = w / (bars * 2f)
        val cx = w / 2f
        val totalBarWidth = barW * bars + barW * (bars - 1)
        val startX = cx - totalBarWidth / 2f

        for (i in 0 until bars) {
            val scale = (animators[i].animatedValue as Float) * audioMult
            val barH = (h * 0.85f * scale).coerceAtLeast(h * 0.12f)
            val x = startX + i * barW * 2f
            barPaint.color = barColors[i]
            barPaint.alpha = (220 * scale).toInt().coerceIn(60, 220)
            val top = (h - barH) / 2f
            canvas.drawRoundRect(x, top, x + barW, top + barH, barW / 2f, barW / 2f, barPaint)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// JackStrandsView  — WebGL/React Strands converted to AGSL RuntimeShader
// ─────────────────────────────────────────────────────────────────────────────
@androidx.annotation.RequiresApi(Build.VERSION_CODES.TIRAMISU)
class JackStrandsView(context: Context) : View(context) {

    private val AGSL_STRANDS = """
        uniform float uTime;
        uniform vec2 uResolution;
        uniform vec3 uColor0;
        uniform vec3 uColor1;
        uniform vec3 uColor2;
        uniform float uAudioLevel;

        const float PI = 3.14159265;

        vec3 samplePalette(float t) {
            t = fract(t);
            float scaled = t * 3.0;
            int idx = int(floor(scaled));
            float blend = fract(scaled);
            if (idx == 0) return mix(uColor0, uColor1, blend);
            if (idx == 1) return mix(uColor1, uColor2, blend);
            return mix(uColor2, uColor0, blend);
        }

        half4 main(vec2 fragCoord) {
            vec2 uv = (fragCoord.xy - 0.5 * uResolution.xy) / uResolution.xy; 

            float e = 0.06 + 0.6 * 0.94; 
            float env = pow(max(cos(uv.x * PI * 1.3), 0.0), 3.0); 

            vec3 col = vec3(0.0);

            // Audio level boosts the wave amplitude significantly
            float dynamicAmp = 1.0 + (uAudioLevel * 5.0);
            float dynamicThick = 0.7 + (uAudioLevel * 1.5);
            
            float waveX = uv.x * 5.0; 
            float waveY = uv.y * 3.0;

            for (int i = 0; i < 3; i++) {
                float fi = float(i);
                float ph = fi * 1.7; 
                float freq = (2.0 + fi * 0.35); 
                float spd = 1.4 + fi * 1.2;

                float tt = uTime * 0.5; 
                float w = sin(waveX * freq + tt * spd + ph) * 0.60
                        + sin(waveX * freq * 1.1 - tt * spd * 0.7 + ph * 1.7) * 0.40;

                float amp = (0.1 + 0.02 * e) * env * dynamicAmp; 
                float y = w * amp;

                float d = abs(waveY - y);
                float thick = (0.001 + 0.05 * e) * (0.35 + env) * dynamicThick; 
                float g = thick / (d + thick * 0.45);
                g = g * g;

                float h = fi / 3.0 + waveX * 0.30 + uTime * 0.04; 
                col += samplePalette(h) * g * env;
            }

            col *= 0.45 + 0.7 * e;
            col = 1.0 - exp(-col * 2.6); 

            float gray = dot(col, vec3(0.2126, 0.7152, 0.0722));
            col = max(mix(vec3(gray), col, 1.5), 0.0); 

            float lum = max(max(col.r, col.g), col.b);
            float alpha = clamp(lum, 0.0, 1.0);

            return half4(half3(col * alpha), half(alpha));
        }
    """

    private val shader = RuntimeShader(AGSL_STRANDS)
    private val paint = Paint().apply { this.shader = this@JackStrandsView.shader }
    private val startTime = System.currentTimeMillis()
    private var isPlaying = false
    private var currentAudioLevel = 0f

    init {
        setColors(0xFF9C27B0.toInt(), 0xFF5C6BC0.toInt(), 0xFF00ACC1.toInt())
        shader.setFloatUniform("uAudioLevel", 0f)
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        isPlaying = true
        scheduleNextFrame()
    }

    override fun onDetachedFromWindow() {
        isPlaying = false
        android.view.Choreographer.getInstance().removeFrameCallback(frameCallback)
        super.onDetachedFromWindow()
    }

    private val frameCallback = android.view.Choreographer.FrameCallback {
        if (isPlaying) {
            invalidate()
            scheduleNextFrame()
        }
    }

    private fun scheduleNextFrame() {
        if (isPlaying) android.view.Choreographer.getInstance().postFrameCallback(frameCallback)
    }

    fun setMode(mode: String) {
        when (mode) {
            JackOverlayService.MODE_LISTENING -> setColors(0xFF9C27B0.toInt(), 0xFF5C6BC0.toInt(), 0xFF7B1FA2.toInt())
            JackOverlayService.MODE_THINKING  -> setColors(0xFF00ACC1.toInt(), 0xFF00897B.toInt(), 0xFF006064.toInt())
            JackOverlayService.MODE_EXECUTING -> setColors(0xFFE53935.toInt(), 0xFFFB8C00.toInt(), 0xFFB71C1C.toInt())
            JackOverlayService.MODE_SPEAKING  -> setColors(0xFF43A047.toInt(), 0xFF7CB342.toInt(), 0xFF2E7D32.toInt())
            else -> setColors(0xFF9C27B0.toInt(), 0xFF5C6BC0.toInt(), 0xFF00ACC1.toInt())
        }
    }

    private fun setColors(c0: Int, c1: Int, c2: Int) {
        shader.setFloatUniform("uColor0", floatArrayOf(Color.red(c0)/255f, Color.green(c0)/255f, Color.blue(c0)/255f))
        shader.setFloatUniform("uColor1", floatArrayOf(Color.red(c1)/255f, Color.green(c1)/255f, Color.blue(c1)/255f))
        shader.setFloatUniform("uColor2", floatArrayOf(Color.red(c2)/255f, Color.green(c2)/255f, Color.blue(c2)/255f))
        invalidate()
    }

    fun setAudioLevel(norm: Float) {
        currentAudioLevel = norm
        shader.setFloatUniform("uAudioLevel", currentAudioLevel)
        invalidate()
    }

    override fun onDraw(canvas: Canvas) {
        if (!isPlaying) return
        val w = width.toFloat()
        val h = height.toFloat()
        val t = (System.currentTimeMillis() - startTime) / 1000f

        shader.setFloatUniform("uTime", t)
        shader.setFloatUniform("uResolution", w, h)
        canvas.drawRect(0f, 0f, w, h, paint)
        // Choreographer callback in scheduleNextFrame() drives next frame — no manual invalidate here.
    }
}
