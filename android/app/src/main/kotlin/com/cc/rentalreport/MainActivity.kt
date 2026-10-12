package com.cc.rentalreport

import android.content.pm.ApplicationInfo
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "rentalreport/screenshot")
            .setMethodCallHandler { call, result ->
                val debugBuild = applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0
                val capture = debugBuild && intent.getBooleanExtra("APP_STORE_SCREENSHOT_MODE", false)
                val scene = if (capture) intent.getStringExtra("APP_STORE_SCREENSHOT_SCENE") else null
                when (call.method) {
                    "getInitialScene" -> result.success(scene)
                    "getLaunchContext" -> result.success(mapOf("screenshotMode" to capture, "scene" to scene))
                    else -> result.notImplemented()
                }
            }
    }
}
