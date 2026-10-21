package com.example.study_companion

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator

class MainActivity : FlutterActivity() {
    private var ringtone: Ringtone? = null
    private val handler = Handler(Looper.getMainLooper())
    private val stopAlert = Runnable { stopReminder() }

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
    }

    override fun onDestroy() {
        handler.removeCallbacks(stopAlert)
        stopReminder()
        super.onDestroy()
    }
}
