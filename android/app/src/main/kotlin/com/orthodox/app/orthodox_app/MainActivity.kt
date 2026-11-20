package com.orthodox.app.orthodox_app

import android.content.pm.ApplicationInfo
import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    private val securityChannel = "com.orthodox.app/security"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, securityChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecureScreen" -> {
                        val enable = call.argument<Boolean>("enable") ?: false
                        runOnUiThread {
                            if (enable) {
                                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            } else {
                                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            }
                        }
                        result.success(true)
                    }
                    "checkDeviceIntegrity" -> {
                        val info = mapOf(
                            "isRooted" to isDeviceRooted(),
                            "isDebuggable" to ((applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0),
                            "isEmulator" to isRunningOnEmulator()
                        )
                        result.success(info)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun isDeviceRooted(): Boolean {
        val buildTags = Build.TAGS
        if (buildTags != null && buildTags.contains("test-keys")) {
            return true
        }
        val suspiciousPaths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su",
            "/su/bin/su",
            "/sbin/.magisk",
            "/data/adb/magisk"
        )
        return suspiciousPaths.any { path ->
            try {
                File(path).exists()
            } catch (_: SecurityException) {
                false
            }
        }
    }

    private fun isRunningOnEmulator(): Boolean {
        return (Build.FINGERPRINT.startsWith("generic")
                || Build.FINGERPRINT.startsWith("unknown")
                || Build.MODEL.contains("google_sdk")
                || Build.MODEL.contains("Emulator")
                || Build.MODEL.contains("Android SDK built for x86")
                || Build.MANUFACTURER.contains("Genymotion")
                || (Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic")))
    }
}
