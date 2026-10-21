package com.example.study_companion

import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator

class MainActivity : FlutterActivity() {
    private var ringtone: Ringtone? = null
    private val handler = Handler(Looper.getMainLooper())
    private val stopAlert = Runnable { stopReminder() }
    private val TAG = "MainActivity"

    @Suppress("DEPRECATION")
    private fun stopReminder() {
        ringtone?.stop()
        ringtone = null
        (getSystemService(VIBRATOR_SERVICE) as Vibrator).cancel()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "study_companion/reminder")
            .setMethodCallHandler { call, result ->
                if (call.method != "play" && call.method != "stop") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                handler.removeCallbacks(stopAlert)
                stopReminder()
                if (call.method == "stop") {
                    result.success(null)
                    return@setMethodCallHandler
                }
                val errors = mutableListOf<String>()
                val attributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()
                try {
                    val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                        ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                    ringtone = RingtoneManager.getRingtone(this, uri)
                    if (ringtone == null) errors.add("手机没有可用的闹钟铃声")
                    ringtone?.audioAttributes = attributes
                    ringtone?.play()
                } catch (e: Exception) { errors.add("铃声播放失败") }
                try {
                    @Suppress("DEPRECATION")
                    val vibrator = getSystemService(VIBRATOR_SERVICE) as Vibrator
                    val pattern = longArrayOf(0, 600, 300, 600, 300, 600)
                    if (!vibrator.hasVibrator()) errors.add("设备不支持震动")
                    @Suppress("DEPRECATION")
                    if (Build.VERSION.SDK_INT >= 26) {
                        vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1), attributes)
                    } else {
                        vibrator.vibrate(pattern, -1, attributes)
                    }
                } catch (e: Exception) { errors.add("震动调用失败") }
                handler.postDelayed(stopAlert, 5000)
                result.success(errors.joinToString("；"))
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "study_companion/overlay")
            .setMethodCallHandler { call, result ->
                Log.d(TAG, "Overlay method called: ${call.method}")
                when (call.method) {
                    "canDrawOverlays" -> {
                        val canDraw = Settings.canDrawOverlays(this)
                        Log.d(TAG, "canDrawOverlays: $canDraw")
                        result.success(canDraw)
                    }
                    "requestOverlayPermission" -> {
                        Log.d(TAG, "requestOverlayPermission called")
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
                            intent.data = android.net.Uri.parse("package:$packageName")
                            startActivity(intent)
                        }
                        result.success(null)
                    }
                    "startOverlay" -> {
                        val subject = call.argument<String>("subject") ?: "学习"
                        Log.d(TAG, "startOverlay called with subject: $subject")
                        val intent = Intent(this, TimerOverlayService::class.java).apply {
                            action = TimerOverlayService.ACTION_START
                            putExtra(TimerOverlayService.EXTRA_SUBJECT, subject)
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        Log.d(TAG, "Service started")
                        result.success(null)
                    }
                    "updateOverlay" -> {
                        val time = call.argument<String>("time") ?: "00:00"
                        val subject = call.argument<String>("subject")
                        Log.d(TAG, "updateOverlay called with time: $time, subject: $subject")
                        val intent = Intent(this, TimerOverlayService::class.java).apply {
                            action = TimerOverlayService.ACTION_UPDATE
                            putExtra(TimerOverlayService.EXTRA_TIME, time)
                            putExtra(TimerOverlayService.EXTRA_SUBJECT, subject)
                        }
                        startService(intent)
                        result.success(null)
                    }
                    "stopOverlay" -> {
                        Log.d(TAG, "stopOverlay called")
                        val intent = Intent(this, TimerOverlayService::class.java).apply {
                            action = TimerOverlayService.ACTION_STOP
                        }
                        startService(intent)
                        result.success(null)
                    }
                    "isOverlayRunning" -> {
                        val running = TimerOverlayService.isRunning
                        Log.d(TAG, "isOverlayRunning: $running")
                        result.success(running)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        handler.removeCallbacks(stopAlert)
        stopReminder()
        super.onDestroy()
    }
}
