package com.mindr.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.annotation.NonNull
import androidx.core.app.NotificationManagerCompat
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.mindr.alarm.models.AlarmEntity
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar
import java.util.Date

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.mindr.alarm/alarm_trigger"

    companion object {
        fun scheduleAlarm(context: Context, alarmJson: String) {
            val gson = Gson()
            val mapType = object: TypeToken<Map<String, Any>>() {}.type
            val alarmMap: Map<String, Any> = gson.fromJson(alarmJson, mapType)
            val alarm = AlarmEntity.fromMap(alarmMap)

            val upcomingTime = alarm.time.clone() as Calendar
            upcomingTime.add(Calendar.HOUR, -2) // Subtract 2 hours
            setAlarmService(context, upcomingTime, "upcoming alarm", alarm)

            val triggerTime = alarm.time
            setAlarmService(context, triggerTime, "trigger alarm", alarm)
        }

        fun setAlarmService(context: Context, triggerTime: Calendar, action: String, data: AlarmEntity) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val alarmIntent = Intent(context, AlarmReceiver::class.java).let { intent ->
                intent.action = action
                intent.putExtra("EXTRA_ALARM_JSON", Gson().toJson(data.toMap()))
                PendingIntent.getBroadcast(context, data.id, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE)
            }

            // AlarmManager.AlarmClockInfo is used to set an exact alarm that is allowed to interrupt Doze mode
            val info = AlarmManager.AlarmClockInfo(triggerTime.timeInMillis, alarmIntent)
            alarmManager.setAlarmClock(info, alarmIntent)
        }

        fun stopNotification(context: Context, id: Int) {
            val notificationManager = NotificationManagerCompat.from(context)
            notificationManager.cancel(id)
        }

        fun stopTriggerService(context: Context, id: Int) {
            val intent = Intent(context, TriggerAlarmService::class.java)
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pendingIntent: PendingIntent = PendingIntent.getBroadcast(context, id, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE)

            alarmManager.cancel(pendingIntent)
            context.stopService(intent)

            // alarm trigger screen
            val finishIntent = Intent("com.mindr.alarm.ACTION_FINISH")
            context.sendBroadcast(finishIntent)
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val alarm: String = call.argument("alarm") ?: ""
                    scheduleAlarm(context, alarm)
                    result.success(null)
                }
                "removeAlarm" -> {
                    val id = call.argument<String>("id")?.toInt() ?: -1
                    stopTriggerService(context, id)
                    stopNotification(context, id)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }


}
