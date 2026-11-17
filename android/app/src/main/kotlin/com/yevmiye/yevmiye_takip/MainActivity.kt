package com.yevmiye.yevmiye_takip

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.app.NotificationManager
import android.os.Build
import android.provider.MediaStore
import android.provider.Settings
import android.net.Uri
import java.io.File
import java.util.UUID

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.yevmiye/ringtone"
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.yevmiye/alarm_permissions").setMethodCallHandler { call, result ->
            when (call.method) {
                "hasFullScreenIntentPermission" -> {
                    val allowed = Build.VERSION.SDK_INT < 34 ||
                        getSystemService(NotificationManager::class.java).canUseFullScreenIntent()
                    result.success(allowed)
                }
                "openFullScreenIntentSettings" -> {
                    if (Build.VERSION.SDK_INT >= 34) {
                        val intent = Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
                            data = Uri.parse("package:$packageName")
                        }
                        startActivity(intent)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "pickMusic") {
                pendingResult = result
                val intent = Intent(Intent.ACTION_PICK, MediaStore.Audio.Media.EXTERNAL_CONTENT_URI)
                startActivityForResult(intent, 1001)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 1001 && resultCode == RESULT_OK && data != null) {
            val uri: Uri? = data.data
            if (uri != null) {
                try {
                    var name = "Özel Müzik"
                    val cursor = contentResolver.query(uri, arrayOf(MediaStore.Audio.Media.DISPLAY_NAME), null, null, null)
                    if (cursor != null && cursor.moveToFirst()) {
                        val nameIndex = cursor.getColumnIndex(MediaStore.Audio.Media.DISPLAY_NAME)
                        if (nameIndex != -1) {
                            name = cursor.getString(nameIndex)
                        }
                        cursor.close()
                    }

                    val extension = name.substringAfterLast('.', "audio")
                        .replace(Regex("[^A-Za-z0-9]"), "")
                        .ifBlank { "audio" }
                    val directory = File(filesDir, "alarm_sounds").apply { mkdirs() }
                    val file = File(directory, "${UUID.randomUUID()}.$extension")
                    val inputStream = contentResolver.openInputStream(uri)
                        ?: throw IllegalStateException("Ses dosyası okunamadı")
                    inputStream.use { input ->
                        file.outputStream().use { output -> input.copyTo(output) }
                    }
                    
                    val resultMap = mapOf("path" to file.absolutePath, "name" to name)
                    pendingResult?.success(resultMap)
                } catch (e: Exception) {
                    pendingResult?.error("ERROR", e.message, null)
                }
            } else {
                pendingResult?.success(null)
            }
        } else if (requestCode == 1001) {
            pendingResult?.success(null)
        }
    }
}
