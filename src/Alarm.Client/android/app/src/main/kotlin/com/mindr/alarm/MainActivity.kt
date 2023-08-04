package com.mindr.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.annotation.NonNull
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.mindr.alarm.models.AlarmEntity
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.mindr.alarm/alarm_trigger"
    private val gson = Gson()
    private val mapType = object: TypeToken<Map<String, Any>>() {}.type

    companion object {
        const val REQUEST_CODE = 3
    }

    private fun stopAlarm(alarmJson: String) {

    }

    private fun scheduleAlarm(alarmJson: String) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val alarmIntent = Intent(this, AlarmReceiver::class.java).let { intent ->
            intent.putExtra("EXTRA_ALARM_ID", REQUEST_CODE)
            intent.putExtra("EXTRA_ALARM_JSON", alarmJson)  // Pass the alarmJson as an extra
            PendingIntent.getBroadcast(this, REQUEST_CODE, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE)
        }

        // AlarmManager.AlarmClockInfo is used to set an exact alarm that is allowed to interrupt Doze mode
        val alarmMap: Map<String, Any> = gson.fromJson(alarmJson, mapType)
        val alarmEntity = AlarmEntity.fromMap(alarmMap)

        val info = AlarmManager.AlarmClockInfo(alarmEntity.time.time, alarmIntent)
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
                "stopAlarm" -> {
                    val alarm: String = call.argument("alarm") ?: ""
                    stopAlarm(alarm)
                    result.success(null)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

//
//    override fun onCreate(savedInstanceState: Bundle?) {
//        super.onCreate(savedInstanceState)
////        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
////            val intent = Intent()
////            intent.action = Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS
////            startActivity(intent)
////        }
////
////        // Check if the application has the draw over other apps permission.
////        if (!Settings.canDrawOverlays(this)) {
////            // If not, let's create an intent to request it.
////            val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))
////            // Start the activity with the intent, it will take the user to the system settings.
////            startActivityForResult(intent, REQUEST_CODE)
////        }
//    }

//    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
//        if (requestCode == REQUEST_CODE) {
//            if (Settings.canDrawOverlays(this)) {
//                // Permission was granted
//            } else {
//                // Permission was not granted
//            }
//        } else {
//            super.onActivityResult(requestCode, resultCode, data)
//        }
//    }
}
