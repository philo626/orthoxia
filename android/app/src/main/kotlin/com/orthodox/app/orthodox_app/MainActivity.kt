package com.orthodox.app.orthodox_app

import android.content.pm.ApplicationInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.Build
import android.os.ParcelFileDescriptor
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.UUID
import java.util.concurrent.Executors

class MainActivity : FlutterFragmentActivity() {
    private val securityChannel = "com.orthodox.app/security"
    private val pdfChannel = "com.orthodox.app/pdf_renderer"

    private data class OpenPdfDoc(
        val pfd: ParcelFileDescriptor,
        val renderer: PdfRenderer
    )

    // Single-threaded executor guarantees android.graphics.pdf.PdfRenderer is never accessed concurrently.
    private val pdfExecutor = Executors.newSingleThreadExecutor()
    private val openDocs = mutableMapOf<String, OpenPdfDoc>()

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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, pdfChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getBooksCacheDir" -> {
                        val dir = File(cacheDir, "orthodox_books_pdf")
                        if (!dir.exists()) dir.mkdirs()
                        result.success(dir.absolutePath)
                    }
                    "openDocument" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrBlank()) {
                            result.error("INVALID_PATH", "Empty PDF path", null)
                            return@setMethodCallHandler
                        }
                        pdfExecutor.execute {
                            try {
                                val file = File(path)
                                if (!file.exists() || file.length() < 64) {
                                    runOnUiThread {
                                        result.error("NOT_FOUND", "PDF file missing or empty", null)
                                    }
                                    return@execute
                                }
                                val pfd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
                                val renderer = PdfRenderer(pfd)
                                val docId = UUID.randomUUID().toString()
                                openDocs[docId] = OpenPdfDoc(pfd, renderer)
                                val pageCount = renderer.pageCount
                                runOnUiThread {
                                    result.success(mapOf("docId" to docId, "pageCount" to pageCount))
                                }
                            } catch (e: Exception) {
                                runOnUiThread {
                                    result.error("OPEN_FAILED", e.message ?: "Cannot open PDF", null)
                                }
                            }
                        }
                    }
                    "renderPage" -> {
                        val docId = call.argument<String>("docId") ?: ""
                        val pageIndex = call.argument<Int>("pageIndex") ?: 0
                        val targetWidth = (call.argument<Int>("widthPx") ?: 1080).coerceIn(360, 1800)
                        pdfExecutor.execute {
                            try {
                                val doc = openDocs[docId]
                                if (doc == null || pageIndex < 0 || pageIndex >= doc.renderer.pageCount) {
                                    runOnUiThread { result.error("INVALID_PAGE", "Invalid document or page", null) }
                                    return@execute
                                }
                                val page = doc.renderer.openPage(pageIndex)
                                val srcW = page.width.coerceAtLeast(1)
                                val srcH = page.height.coerceAtLeast(1)
                                val scale = targetWidth.toFloat() / srcW.toFloat()
                                val bmpW = targetWidth
                                val bmpH = (srcH * scale).toInt().coerceIn(360, 2800)
                                val bitmap = Bitmap.createBitmap(bmpW, bmpH, Bitmap.Config.ARGB_8888)
                                try {
                                    val canvas = Canvas(bitmap)
                                    canvas.drawColor(Color.WHITE)
                                    page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                                    val out = ByteArrayOutputStream()
                                    bitmap.compress(Bitmap.CompressFormat.JPEG, 88, out)
                                    val bytes = out.toByteArray()
                                    runOnUiThread { result.success(bytes) }
                                } finally {
                                    bitmap.recycle()
                                    page.close()
                                }
                            } catch (e: Exception) {
                                runOnUiThread {
                                    result.error("RENDER_FAILED", e.message ?: "Render error", null)
                                }
                            }
                        }
                    }
                    "closeDocument" -> {
                        val docId = call.argument<String>("docId") ?: ""
                        pdfExecutor.execute {
                            val doc = openDocs.remove(docId)
                            try { doc?.renderer?.close() } catch (_: Exception) {}
                            try { doc?.pfd?.close() } catch (_: Exception) {}
                            runOnUiThread { result.success(true) }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        pdfExecutor.execute {
            for (doc in openDocs.values) {
                try { doc.renderer.close() } catch (_: Exception) {}
                try { doc.pfd.close() } catch (_: Exception) {}
            }
            openDocs.clear()
        }
        pdfExecutor.shutdown()
        super.onDestroy()
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
