package com.mindr.alarm

import android.annotation.SuppressLint
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationManagerCompat
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.mindr.alarm.models.AlarmEntity
import java.util.Calendar

class AlarmService private constructor(private val context: Context) {

    companion object {
        @SuppressLint("StaticFieldLeak")
        @Volatile
        private var INSTANCE: AlarmService? = null

        fun getInstance(context: Context): AlarmService =
                INSTANCE ?: synchronized(this) {
                    INSTANCE ?: AlarmService(context).also { INSTANCE = it }
                }
    }

    fun scheduleAlarm(alarmJson: String) {
        val gson = Gson()
        val mapType = object: TypeToken<Map<String, Any>>() {}.type
        val alarmMap: Map<String, Any> = gson.fromJson(alarmJson, mapType)
        val alarm = AlarmEntity.fromMap(alarmMap)

        val upcomingTime = alarm.time.clone() as Calendar
        upcomingTime.add(Calendar.HOUR, -2) // Subtract 2 hours
        setAlarmService(upcomingTime, "upcoming alarm", alarm)

        val triggerTime = alarm.time
        setAlarmService(triggerTime, "trigger alarm", alarm)
    }

    fun setAlarmService(triggerTime: Calendar, action: String, data: AlarmEntity) {
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

    fun stopNotification(id: Int) {
        val notificationManager = NotificationManagerCompat.from(context)
        notificationManager.cancel(id)
    }

    fun stopTriggerService(id: Int) {
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
