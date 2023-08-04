package com.mindr.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.annotation.NonNull
import com.google.gson.Gson
import com.mindr.alarm.models.AlarmEntity
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.mindr.alarm/alarm_trigger"

    companion object {
        const val REQUEST_CODE = 3
    }

    private val FOREGROUND_SERVICE_ACTION = "com.mindr.alarm.action.FOREGROUND_SERVICE"

    private fun openAlarmScreen(alarmJson: String) {

    }
    private fun scheduleAlarm(alarmJson: String) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val alarmIntent = Intent(this, AlarmReceiver::class.java).let { intent ->
            intent.putExtra("EXTRA_ALARM_ID", REQUEST_CODE)
            intent.putExtra("EXTRA_ALARM_JSON", alarmJson)  // Pass the alarmJson as an extra
            PendingIntent.getBroadcast(this, REQUEST_CODE, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE)
        }

        // AlarmManager.AlarmClockInfo is used to set an exact alarm that is allowed to interrupt Doze mode
        val gson = Gson()
        val alarmEntity = gson.fromJson(alarmJson, AlarmEntity::class.java)
        val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US)
        val date: Date = format.parse(alarmEntity.time) as Date
        val triggerTime = date.time // Convert Date to milliseconds

        val info = AlarmManager.AlarmClockInfo(triggerTime, alarmIntent)
        alarmManager.setAlarmClock(info, alarmIntent)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val alarm: String = call.argument("alarm") ?: ""
                    scheduleAlarm(alarm)
                    result.success(null)
                }
                "openAlarmScreen" -> {
                    val alarm: String = call.argument("alarm") ?: ""
                    openAlarmScreen(alarm)
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
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent()
            intent.action = Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS
            startActivity(intent)
        }

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
                // Permission was not granted
            }
        } else {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }
}
