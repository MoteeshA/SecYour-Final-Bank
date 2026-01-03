package com.example.dummy_bank

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import android.util.Log
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity   // Required for local_auth
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant            // ✅ REQUIRED FOR TTS

class MainActivity : FlutterFragmentActivity() {

    private val CHANNEL = "phishsafe_sdk/screen_recording"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ✅ Register plugins manually (flutter_tts fixes MissingPluginException)
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isScreenRecording" -> {
                    val isRecording = isScreenRecording()
                    result.success(isRecording)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isScreenRecording(): Boolean {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val processes = activityManager.runningAppProcesses ?: return false

        // Known screen recording apps
        val screenRecordKeywords = listOf(
            "az screen", "mobizen", "du recorder",
            "screen recorder", "recorder", "xrecorder", "vidma"
        )

        for (process in processes) {
            val processName = process.processName.lowercase()
            if (screenRecordKeywords.any { keyword -> processName.contains(keyword) }) {
                Log.w("ScreenCheck", "🚨 Possible screen recording process detected: $processName")
                return true
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            val secureFlag = window?.attributes?.flags?.and(WindowManager.LayoutParams.FLAG_SECURE)
            if (secureFlag == 0) {
                // FLAG_SECURE is OFF → screen can be captured
                // return true  // enable if required
            }
        }

        return false
    }
}
