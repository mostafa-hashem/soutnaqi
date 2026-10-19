package com.soutnaqi.app

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.os.PowerManager
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val BACKGROUND_CHANNEL = "com.soutnaqi.app/background"
    private val INTENT_CHANNEL = "com.soutnaqi.app/incoming_media"
    private val STORAGE_CHANNEL = "com.soutnaqi.app/storage"

    private var wakeLock: PowerManager.WakeLock? = null
    private var intentChannel: MethodChannel? = null
    private var initialMediaPath: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ensureSoutNaqiFolders()
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACKGROUND_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "acquireWakeLock" -> {
                        acquireWakeLock()
                        result.success(true)
                    }
                    "releaseWakeLock" -> {
                        releaseWakeLock()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        intentChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INTENT_CHANNEL)
        intentChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialMedia" -> {
                    val path = initialMediaPath
                    initialMediaPath = null
                    result.success(path)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORAGE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initAppFolders" -> {
                        val res = ensureSoutNaqiFolders()
                        result.success(res)
                    }
                    "saveMedia" -> {
                        val sourcePath = call.argument<String>("sourcePath")
                        val fileName = call.argument<String>("fileName")
                        val isVideo = call.argument<Boolean>("isVideo") ?: false

                        if (sourcePath == null || fileName == null) {
                            result.error("INVALID_ARGS", "sourcePath and fileName are required", null)
                            return@setMethodCallHandler
                        }

                        Thread {
                            val saveResult = saveMediaToDCIM(sourcePath, fileName, isVideo)
                            runOnUiThread {
                                result.success(saveResult)
                            }
                        }.start()
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun ensureSoutNaqiFolders(): Map<String, Any> {
        return try {
            val dcim = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM)
            val soutNaqi = File(dcim, "SoutNaqi")
            val videos = File(soutNaqi, "Videos")
            val audio = File(soutNaqi, "Audio")

            if (!videos.exists()) videos.mkdirs()
            if (!audio.exists()) audio.mkdirs()

            mapOf(
                "success" to true,
                "baseDir" to soutNaqi.absolutePath,
                "videosDir" to videos.absolutePath,
                "audioDir" to audio.absolutePath
            )
        } catch (e: Exception) {
            mapOf(
                "success" to false,
                "error" to (e.message ?: "Failed to create folders")
            )
        }
    }

    private fun saveMediaToDCIM(
        sourcePath: String,
        fileName: String,
        isVideo: Boolean
    ): Map<String, Any> {
        val sourceFile = File(sourcePath)
        if (!sourceFile.exists()) {
            return mapOf("success" to false, "error" to "Source file does not exist")
        }

        val subfolder = if (isVideo) "Videos" else "Audio"
        val relativePath = "DCIM/SoutNaqi/$subfolder"
        val mimeType = getMimeType(fileName, isVideo)

        // 1. Direct File Copy attempt (creates folders and saves directly on storage)
        try {
            val dcim = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM)
            val targetDir = File(dcim, "SoutNaqi/$subfolder")
            if (!targetDir.exists()) {
                targetDir.mkdirs()
            }
            if (targetDir.exists() && targetDir.canWrite()) {
                val destFile = File(targetDir, fileName)
                sourceFile.copyTo(destFile, overwrite = true)

                // Index with MediaScanner so Android Gallery / Music player picks it up immediately
                MediaScannerConnection.scanFile(
                    applicationContext,
                    arrayOf(destFile.absolutePath),
                    arrayOf(mimeType),
                    null
                )

                return mapOf(
                    "success" to true,
                    "fullPath" to destFile.absolutePath,
                    "displayPath" to "$relativePath/$fileName"
                )
            }
        } catch (e: Exception) {
            // Fall through to MediaStore
        }

        // 2. MediaStore insertion (Scoped Storage compatible for Android 10, 11, 12, 13, 14, 15)
        try {
            val contentResolver = applicationContext.contentResolver
            val collectionUri = if (isVideo) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                } else {
                    MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                }
            } else {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                } else {
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                }
            }

            var chosenRelativePath = relativePath
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
                    put(MediaStore.MediaColumns.IS_PENDING, 1)
                }
            }

            var itemUri: Uri? = try {
                contentResolver.insert(collectionUri, values)
            } catch (e: Exception) {
                // If audio fails with DCIM relative path on strict Android versions, fallback to Music/SoutNaqi
                if (!isVideo && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    chosenRelativePath = "Music/SoutNaqi"
                    values.put(MediaStore.MediaColumns.RELATIVE_PATH, chosenRelativePath)
                    contentResolver.insert(collectionUri, values)
                } else {
                    throw e
                }
            }

            if (itemUri == null) {
                throw IllegalStateException("Failed to insert into MediaStore")
            }

            contentResolver.openOutputStream(itemUri)?.use { outStream ->
                sourceFile.inputStream().use { inStream ->
                    inStream.copyTo(outStream)
                }
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                values.clear()
                values.put(MediaStore.MediaColumns.IS_PENDING, 0)
                contentResolver.update(itemUri, values, null, null)
            }

            val display = if (chosenRelativePath.endsWith("/")) "$chosenRelativePath$fileName" else "$chosenRelativePath/$fileName"

            return mapOf(
                "success" to true,
                "fullPath" to itemUri.toString(),
                "displayPath" to display
            )
        } catch (e: Exception) {
            return mapOf(
                "success" to false,
                "error" to (e.message ?: "MediaStore write failed")
            )
        }
    }

    private fun getMimeType(fileName: String, isVideo: Boolean): String {
        val extension = fileName.substringAfterLast('.', "").lowercase()
        val mime = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
        if (mime != null) return mime
        return if (isVideo) "video/mp4" else "audio/mp4"
    }

    private fun acquireWakeLock() {
        try {
            if (wakeLock == null) {
                val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                wakeLock = powerManager.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK,
                    "SoutNaqi::ProcessingWakeLock"
                )
                wakeLock?.setReferenceCounted(false)
            }
            if (wakeLock?.isHeld == false) {
                wakeLock?.acquire(20 * 60 * 1000L /* 20 mins */)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        val action = intent.action
        if (Intent.ACTION_SEND == action) {
            val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
            }
            if (uri != null) {
                val path = resolveUriToFile(uri)
                if (path != null) {
                    dispatchMedia(path)
                }
            }
        } else if (Intent.ACTION_VIEW == action) {
            val uri = intent.data
            if (uri != null) {
                val path = resolveUriToFile(uri)
                if (path != null) {
                    dispatchMedia(path)
                }
            }
        }
    }

    private fun dispatchMedia(path: String) {
        if (intentChannel != null) {
            intentChannel?.invokeMethod("onMediaReceived", path)
        } else {
            initialMediaPath = path
        }
    }

    private fun resolveUriToFile(uri: Uri): String? {
        return try {
            if ("file".equals(uri.scheme, ignoreCase = true)) {
                return uri.path
            }
            var fileName = "media_${System.currentTimeMillis()}"
            val cursor = contentResolver.query(uri, null, null, null, null)
            cursor?.use {
                if (it.moveToFirst()) {
                    val index = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (index != -1) {
                        val name = it.getString(index)
                        if (!name.isNullOrBlank()) {
                            fileName = name
                        }
                    }
                }
            }
            val destinationFile = File(cacheDir, fileName)
            contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(destinationFile).use { output ->
                    input.copyTo(output)
                }
            }
            destinationFile.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    override fun onDestroy() {
        releaseWakeLock()
        super.onDestroy()
    }
}
