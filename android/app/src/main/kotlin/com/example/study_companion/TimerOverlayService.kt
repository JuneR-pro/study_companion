package com.example.study_companion

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import androidx.core.app.NotificationCompat

class TimerOverlayService : Service() {
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var timerText: TextView? = null
    private var subjectText: TextView? = null
    private val handler = Handler(Looper.getMainLooper())
    private var updateRunnable: Runnable? = null

    companion object {
        const val ACTION_START = "start"
        const val ACTION_UPDATE = "update"
        const val ACTION_STOP = "stop"
        const val EXTRA_TIME = "time"
        const val EXTRA_SUBJECT = "subject"
        const val EXTRA_STATUS = "status"
        const val CHANNEL_ID = "timer_overlay_channel"
        const val NOTIFICATION_ID = 1001

        var isRunning = false
            private set
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification("计时中..."))
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> showOverlay(intent.getStringExtra(EXTRA_SUBJECT) ?: "学习")
            ACTION_UPDATE -> updateOverlay(
                intent.getStringExtra(EXTRA_TIME) ?: "00:00",
                intent.getStringExtra(EXTRA_SUBJECT)
            )
            ACTION_STOP -> stopOverlay()
        }
        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "计时浮窗",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "显示计时状态的悬浮窗"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(text: String): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("学习计时中")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_menu_recent_history)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
    }

    private fun showOverlay(subject: String) {
        if (overlayView != null) return

        isRunning = true
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 0
            y = 100
        }

        overlayView = createOverlayView(subject)
        windowManager?.addView(overlayView, params)
    }

    private fun createOverlayView(subject: String): View {
        val density = resources.displayMetrics.density
        val padding = (12 * density).toInt()
        val cornerRadius = 16 * density

        val container = android.widget.FrameLayout(this).apply {
            setBackgroundColor(Color.parseColor("#E6F44336"))
            val shape = android.graphics.drawable.GradientDrawable().apply {
                setColor(Color.parseColor("#E6F44336"))
                this.cornerRadius = cornerRadius
            }
            background = shape
            setPadding(padding, padding, padding, padding)
        }

        val linearLayout = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            setPadding(padding, padding, padding, padding)
        }

        subjectText = TextView(this).apply {
            text = subject
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            gravity = Gravity.CENTER
        }

        timerText = TextView(this).apply {
            text = "00:00"
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            gravity = Gravity.CENTER
        }

        linearLayout.addView(subjectText)
        linearLayout.addView(timerText)
        container.addView(linearLayout)

        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f

        container.setOnTouchListener { _, event ->
            val params = container.layoutParams as WindowManager.LayoutParams
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params.x
                    initialY = params.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    params.x = initialX + (event.rawX - initialTouchX).toInt()
                    params.y = initialY + (event.rawY - initialTouchY).toInt()
                    windowManager?.updateViewLayout(container, params)
                    true
                }
                else -> false
            }
        }

        return container
    }

    private fun updateOverlay(time: String, subject: String?) {
        handler.post {
            timerText?.text = time
            if (subject != null) {
                subjectText?.text = subject
            }
            val notification = createNotification("$subject - $time")
            val manager = getSystemService(NotificationManager::class.java)
            manager.notify(NOTIFICATION_ID, notification)
        }
    }

    private fun stopOverlay() {
        isRunning = false
        updateRunnable?.let { handler.removeCallbacks(it) }
        updateRunnable = null

        if (overlayView != null) {
            windowManager?.removeView(overlayView)
            overlayView = null
            timerText = null
            subjectText = null
        }

        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onDestroy() {
        stopOverlay()
        super.onDestroy()
    }
}
