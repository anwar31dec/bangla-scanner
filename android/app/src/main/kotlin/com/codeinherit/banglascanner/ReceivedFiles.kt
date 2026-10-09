package com.codeinherit.banglascanner

import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors

/**
 * Files shared to the app (ACTION_SEND / SEND_MULTIPLE) or opened with it
 * (ACTION_VIEW). Each incoming URI is copied into `cache/received/<time>/`
 * because content URIs from other apps may stop working as soon as the
 * sender is closed. Dart is told through `filesReceived`, or asks with
 * `takeInitialFiles` for anything that arrived before it was listening.
 */
class ReceivedFiles(private val context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, CHANNEL)
    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    /** Files copied but not yet handed to Dart. */
    private val pending = ArrayList<String>()
    private var dartListening = false

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "takeInitialFiles" -> {
                    dartListening = true
                    val files = ArrayList(pending)
                    pending.clear()
                    result.success(files)
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Returns true when [intent] carried files for us. */
    fun handle(intent: Intent?): Boolean {
        if (intent == null) return false
        val uris = urisOf(intent)
        if (uris.isEmpty()) return false
        executor.execute {
            val paths = copyAll(uris)
            main.post {
                if (paths.isEmpty()) return@post
                if (dartListening) {
                    channel.invokeMethod("filesReceived", paths)
                } else {
                    pending.addAll(paths)
                }
            }
        }
        return true
    }

    private fun urisOf(intent: Intent): List<Uri> {
        return when (intent.action) {
            Intent.ACTION_SEND -> listOfNotNull(streamExtra(intent))
            Intent.ACTION_SEND_MULTIPLE -> streamExtras(intent)
            Intent.ACTION_VIEW -> listOfNotNull(intent.data)
            else -> emptyList()
        }
    }

    @Suppress("DEPRECATION")
    private fun streamExtra(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }

    @Suppress("DEPRECATION")
    private fun streamExtras(intent: Intent): List<Uri> =
        (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM)
        }) ?: emptyList()

    private fun copyAll(uris: List<Uri>): List<String> {
        val dir = File(File(context.cacheDir, FOLDER), System.currentTimeMillis().toString())
        dir.mkdirs()
        val paths = ArrayList<String>()
        val used = HashSet<String>()
        for (uri in uris) {
            try {
                var name = fileName(uri)
                while (!used.add(name.lowercase())) name = "${used.size}_$name"
                val target = File(dir, name)
                context.contentResolver.openInputStream(uri).use { input ->
                    requireNotNull(input) { "Cannot read $uri" }
                    FileOutputStream(target).use { input.copyTo(it) }
                }
                paths.add(target.absolutePath)
            } catch (_: Exception) {
                // Skip what cannot be read; Dart reports if nothing is left.
            }
        }
        return paths
    }

    /** Display name with an extension Dart can recognise (images or .pdf). */
    private fun fileName(uri: Uri): String {
        var name: String? = null
        if (uri.scheme == ContentResolver.SCHEME_CONTENT) {
            runCatching {
                context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use {
                    if (it.moveToFirst()) name = it.getString(0)
                }
            }
        }
        if (name.isNullOrBlank()) name = uri.lastPathSegment?.substringAfterLast('/')
        var base = (name ?: "file").replace(Regex("[\\\\/:*?\"<>|]"), "_")
        val mime = context.contentResolver.getType(uri) ?: MimeTypeMap.getSingleton()
            .getMimeTypeFromExtension(base.substringAfterLast('.', "").lowercase())
        val hasExtension = base.contains('.') && base.substringAfterLast('.').length in 2..5
        if (!hasExtension) {
            val ext = when {
                mime == "application/pdf" -> "pdf"
                mime != null -> MimeTypeMap.getSingleton().getExtensionFromMimeType(mime) ?: "jpg"
                else -> "jpg"
            }
            base = "$base.$ext"
        }
        return base
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        executor.shutdown()
    }

    companion object {
        const val CHANNEL = "com.codeinherit.banglascanner/received"
        private const val FOLDER = "received"
    }
}
