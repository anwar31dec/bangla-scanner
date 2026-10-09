package com.codeinherit.banglascanner

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors
import kotlin.math.max
import kotlin.math.roundToInt

/**
 * Renders PDF pages to JPEG files for the "Import PDF" feature. Dart opens a
 * document, renders pages one by one (so it can show progress) and closes it.
 *
 * Methods: `open {path} -> {id, pageCount}`, `render {id, index, maxEdge,
 * path} -> path`, `close {id}`. Errors: `pdf_locked` for password protected
 * files, `pdf_invalid` for anything that is not a readable PDF.
 */
class PdfPageRenderer(messenger: BinaryMessenger) {
    private class OpenDocument(val descriptor: ParcelFileDescriptor, val renderer: PdfRenderer)

    private val documents = HashMap<Int, OpenDocument>()
    private var nextId = 1
    private val executor = Executors.newSingleThreadExecutor()
    private val channel = MethodChannel(messenger, CHANNEL)

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "open" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.error("bad_args", "path is required", null)
                    } else {
                        executor.execute { open(path, result) }
                    }
                }
                "render" -> {
                    val id = call.argument<Int>("id")
                    val index = call.argument<Int>("index")
                    val maxEdge = call.argument<Int>("maxEdge") ?: 2339
                    val path = call.argument<String>("path")
                    if (id == null || index == null || path == null) {
                        result.error("bad_args", "id, index and path are required", null)
                    } else {
                        executor.execute { render(id, index, maxEdge, path, result) }
                    }
                }
                "close" -> {
                    val id = call.argument<Int>("id")
                    executor.execute {
                        synchronized(documents) { documents.remove(id) }?.let {
                            runCatching { it.renderer.close() }
                            runCatching { it.descriptor.close() }
                        }
                        reply { result.success(null) }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun open(path: String, result: MethodChannel.Result) {
        val file = File(path)
        if (!file.exists()) {
            reply { result.error("pdf_invalid", "File not found", null) }
            return
        }
        var descriptor: ParcelFileDescriptor? = null
        try {
            descriptor = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
            val renderer = PdfRenderer(descriptor)
            val id = synchronized(documents) {
                val id = nextId++
                documents[id] = OpenDocument(descriptor, renderer)
                id
            }
            reply { result.success(mapOf("id" to id, "pageCount" to renderer.pageCount)) }
        } catch (e: SecurityException) {
            // PdfRenderer cannot open password protected files.
            runCatching { descriptor?.close() }
            reply { result.error("pdf_locked", e.message, null) }
        } catch (e: Exception) {
            runCatching { descriptor?.close() }
            reply { result.error("pdf_invalid", e.message, null) }
        }
    }

    private fun render(id: Int, index: Int, maxEdge: Int, path: String, result: MethodChannel.Result) {
        val doc = synchronized(documents) { documents[id] }
        if (doc == null) {
            reply { result.error("pdf_invalid", "Document is not open", null) }
            return
        }
        try {
            // PdfRenderer is not thread safe; all work runs on the single executor.
            doc.renderer.openPage(index).use { page ->
                // Page size is in points (1/72 in); scale so the long edge is maxEdge px.
                val scale = maxEdge.toFloat() / max(page.width, page.height).toFloat()
                val width = max(1, (page.width * scale).roundToInt())
                val height = max(1, (page.height * scale).roundToInt())
                val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                try {
                    // Transparent areas of a PDF page are paper, i.e. white.
                    Canvas(bitmap).drawColor(Color.WHITE)
                    page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                    val target = File(path)
                    target.parentFile?.mkdirs()
                    FileOutputStream(target).use { out ->
                        bitmap.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, out)
                    }
                } finally {
                    bitmap.recycle()
                }
            }
            reply { result.success(path) }
        } catch (e: OutOfMemoryError) {
            reply { result.error("render_failed", "Page too large", null) }
        } catch (e: Exception) {
            reply { result.error("pdf_invalid", e.message, null) }
        }
    }

    private fun reply(block: () -> Unit) {
        android.os.Handler(android.os.Looper.getMainLooper()).post(block)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        executor.execute {
            synchronized(documents) {
                documents.values.forEach {
                    runCatching { it.renderer.close() }
                    runCatching { it.descriptor.close() }
                }
                documents.clear()
            }
        }
        executor.shutdown()
    }

    companion object {
        const val CHANNEL = "com.codeinherit.banglascanner/pdf"
        private const val JPEG_QUALITY = 92
    }
}
