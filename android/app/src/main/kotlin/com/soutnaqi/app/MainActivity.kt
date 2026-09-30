package com.soutnaqi.app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.OpenableColumns
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val BACKGROUND_CHANNEL = "com.soutnaqi.app/background"
    private val INTENT_CHANNEL = "com.soutnaqi.app/incoming_media"

    private var wakeLock: PowerManager.WakeLock? = null
    private var intentChannel: MethodChannel? = null
    private var initialMediaPath: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
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
