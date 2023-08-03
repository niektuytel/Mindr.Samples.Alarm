package com.mindr.alarm

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.core.app.AlarmManagerCompat
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.mindr.alarm/alarm_trigger"
    private val REQUEST_CODE = 3;
    private val FOREGROUND_SERVICE_ACTION = "com.mindr.alarm.action.FOREGROUND_SERVICE"

    private fun scheduleAlarm(triggerTime: Long) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val alarmIntent = Intent(this, AlarmReceiver::class.java).let { intent ->
            intent.putExtra("EXTRA_ALARM_ID", REQUEST_CODE)
            PendingIntent.getBroadcast(this, REQUEST_CODE, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE)
        }

        // AlarmManager.AlarmClockInfo is used to set an exact alarm that is allowed to interrupt Doze mode
        val info = AlarmManager.AlarmClockInfo(triggerTime, alarmIntent)
        alarmManager.setAlarmClock(info, alarmIntent)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val triggerTime: Long = call.argument("triggerTime") ?: System.currentTimeMillis()
                    scheduleAlarm(triggerTime)
                    result.success(null)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Check if the application has the draw over other apps permission.
        if (!Settings.canDrawOverlays(this)) {
            // If not, let's create an intent to request it.
            val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))
            // Start the activity with the intent, it will take the user to the system settings.
            startActivityForResult(intent, REQUEST_CODE)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == REQUEST_CODE) {
            if (Settings.canDrawOverlays(this)) {
                // Permission was granted
            } else {
                // Permission was not granted, let's create an intent to request it.
                val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))
                // Start the activity with the intent, it will take the user to the system settings.
                startActivityForResult(intent, REQUEST_CODE)
            }
        } else {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }
}
