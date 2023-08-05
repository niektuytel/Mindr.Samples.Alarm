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
import java.util.Date

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.mindr.alarm/alarm_trigger"

    companion object {
        const val REQUEST_CODE = 3

        fun scheduleAlarm(context: Context, alarmJson: String) {
            val gson = Gson()
            val mapType = object: TypeToken<Map<String, Any>>() {}.type
            val alarmMap: Map<String, Any> = gson.fromJson(alarmJson, mapType)
            val alarm = AlarmEntity.fromMap(alarmMap)

            val twoHoursInMilliseconds = 2 * 60 * 60 * 1000
            val upcomingTime = Date(alarm.time.time - twoHoursInMilliseconds)// (DateTime.Now - 2hours)
            setAlarmService(context, upcomingTime, "upcoming alarm", alarm)

            val triggerTime = alarm.time
            setAlarmService(context, triggerTime, "trigger alarm", alarm)
        }

        fun setAlarmService(context: Context, triggerTime: Date, action: String, data: AlarmEntity) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val alarmIntent = Intent(context, AlarmReceiver::class.java).let { intent ->
                intent.action = action
                intent.putExtra("EXTRA_ALARM_JSON", Gson().toJson(data.toMap()))
                PendingIntent.getBroadcast(context, REQUEST_CODE, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE)
            }

            // AlarmManager.AlarmClockInfo is used to set an exact alarm that is allowed to interrupt Doze mode
            val info = AlarmManager.AlarmClockInfo(triggerTime.time, alarmIntent)
            alarmManager.setAlarmClock(info, alarmIntent)
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val alarm: String = call.argument("alarm") ?: ""
                    scheduleAlarm(this, alarm)
                    result.success(null)
                }
                "stopAlarm" -> {
                    val alarm: String = call.argument("alarm") ?: ""
//                    stopAlarm(alarm)
                    result.success(null)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
