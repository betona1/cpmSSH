package com.betona1.cpm_ssh_terminal

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.betona1.cpm_ssh_terminal/ime"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "toggleKoreanEnglish" -> {
                    val downEvent = KeyEvent(
                        System.currentTimeMillis(), System.currentTimeMillis(),
                        KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_SPACE, 0,
                        KeyEvent.META_SHIFT_ON
                    )
                    val upEvent = KeyEvent(
                        System.currentTimeMillis(), System.currentTimeMillis(),
                        KeyEvent.ACTION_UP, KeyEvent.KEYCODE_SPACE, 0,
                        KeyEvent.META_SHIFT_ON
                    )
                    dispatchKeyEvent(downEvent)
                    dispatchKeyEvent(upEvent)
                    result.success(true)
                }
                "startFloatingButton" -> {
                    if (canDrawOverlays()) {
                        startFloatingService()
                        result.success(true)
                    } else {
                        requestOverlayPermission()
                        result.success(false)
                    }
                }
                "stopFloatingButton" -> {
                    stopFloatingService()
                    result.success(true)
                }
                "isFloatingButtonRunning" -> {
                    result.success(HanEngFloatingService.isRunning)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun canDrawOverlays(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else true
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivityForResult(intent, 1234)
        }
    }

    private fun startFloatingService() {
        val intent = Intent(this, HanEngFloatingService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopFloatingService() {
        stopService(Intent(this, HanEngFloatingService::class.java))
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 1234 && canDrawOverlays()) {
            startFloatingService()
        }
    }
}
