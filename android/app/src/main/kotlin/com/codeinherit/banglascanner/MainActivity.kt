package com.codeinherit.banglascanner

import android.content.ContentValues
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterFragmentActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // Only Android 9 and below need WRITE_EXTERNAL_STORAGE.
                "needsStoragePermission" -> result.success(Build.VERSION.SDK_INT < Build.VERSION_CODES.Q)
                "saveToDownloads" -> {
                    val path = call.argument<String>("path")
                    val name = call.argument<String>("name")
                    val mime = call.argument<String>("mime") ?: "application/octet-stream"
                    if (path == null || name == null) {
                        result.error("bad_args", "path and name are required", null)
                        return@setMethodCallHandler
                    }
                    // Copying can be slow for large files; keep it off the UI thread.
                    Thread {
                        try {
                            val saved = saveToDownloads(File(path), name, mime)
                            runOnUiThread { result.success(saved) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("save_failed", e.message, null) }
                        }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Copies [source] into Downloads/Bangla Scanner and returns a display path.
     * Android 10+ uses MediaStore (no permission needed); older versions write
     * to the public Downloads folder (WRITE_EXTERNAL_STORAGE, requested in Dart).
     */
    private fun saveToDownloads(source: File, name: String, mime: String): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, name)
                put(MediaStore.MediaColumns.MIME_TYPE, mime)
                put(MediaStore.MediaColumns.RELATIVE_PATH, "${Environment.DIRECTORY_DOWNLOADS}/$FOLDER")
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val resolver = applicationContext.contentResolver
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("MediaStore insert failed")
            try {
                resolver.openOutputStream(uri).use { out ->
                    requireNotNull(out) { "Cannot open output stream" }
                    FileInputStream(source).use { it.copyTo(out) }
                }
                values.clear()
                values.put(MediaStore.MediaColumns.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
            } catch (e: Exception) {
                resolver.delete(uri, null, null)
                throw e
            }
            return "${Environment.DIRECTORY_DOWNLOADS}/$FOLDER/$name"
        }

        @Suppress("DEPRECATION")
        val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), FOLDER)
        if (!dir.exists() && !dir.mkdirs()) throw IllegalStateException("Cannot create $dir")
        var target = File(dir, name)
        var i = 1
        while (target.exists()) {
            target = File(dir, "${name.substringBeforeLast('.')} ($i).${name.substringAfterLast('.', "")}")
            i++
        }
        source.copyTo(target)
        MediaScannerConnection.scanFile(this, arrayOf(target.absolutePath), arrayOf(mime), null)
        return target.absolutePath
    }

    companion object {
        private const val CHANNEL = "com.codeinherit.banglascanner/storage"
        private const val FOLDER = "Bangla Scanner"
    }
}
