package com.mindr.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.core.content.ContextCompat.getSystemService
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.mindr.alarm.MainActivity.Companion.REQUEST_CODE
import com.mindr.alarm.models.AlarmEntity
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class AlarmReceiver : BroadcastReceiver() {

    private val gson = Gson()
    private val mapType = object: TypeToken<Map<String, Any>>() {}.type
    private lateinit var alarmJson: String;
    private lateinit var alarmEntity: AlarmEntity;

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        println("AlarmReceiver.action: $action")

        // Retrieve the alarmJson from the intent extras
        alarmJson = intent.getStringExtra("EXTRA_ALARM_JSON")!!
        var alarmMap: Map<String, Any> = gson.fromJson(alarmJson, mapType)
        alarmEntity = AlarmEntity.fromMap(alarmMap)
        println("AlarmReceiver.alarmJson: $alarmJson")

        // Create a notification manager
        val notificationManager = NotificationManagerCompat.from(context)

        when (action) {
            "SNOOZE_ACTION" -> {
                // Set a new alarm over 10 minutes
                val tenMinutesInMilliseconds = 10 * 60 * 1000
                alarmEntity.time = Date(alarmEntity.time.time + tenMinutesInMilliseconds)
                alarmMap = alarmEntity.toMap()
                alarmJson = gson.toJson(alarmMap)

                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                val alarmIntent = Intent(context, AlarmReceiver::class.java).let { intent ->
                    intent.putExtra("EXTRA_ALARM_ID", REQUEST_CODE)
                    intent.putExtra("EXTRA_ALARM_JSON", alarmJson)  // Pass the alarmJson as an extra
                    PendingIntent.getBroadcast(context, REQUEST_CODE, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE)
                }

                // AlarmManager.AlarmClockInfo is used to set an exact alarm that is allowed to interrupt Doze mode
                val info = AlarmManager.AlarmClockInfo(alarmEntity.time.time, alarmIntent)
                alarmManager.setAlarmClock(info, alarmIntent)

                // TODO: show snoozed notification(hosted on flutter)

                // TODO: update sql database time of item(hosted on flutter)

                // Stop the service + FullscreenActivity
                val serviceIntent = Intent(context, AlarmService::class.java)
                context.stopService(serviceIntent)
                val finishIntent = Intent("com.mindr.alarm.ACTION_FINISH")
                context.sendBroadcast(finishIntent)
            }
            "DISMISS_ACTION" -> {
                // Set a new notification if scheduledDays are set
                if (alarmEntity.scheduledDays.isNotEmpty()) {
                    val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                    val alarmIntent = Intent(context, AlarmReceiver::class.java).let { intent ->
                        intent.putExtra("EXTRA_ALARM_JSON", alarmJson)  // Pass the alarmJson as an extra
                        PendingIntent.getBroadcast(context, REQUEST_CODE, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE)
                    }

                    // AlarmManager.AlarmClockInfo is used to set an exact alarm that is allowed to interrupt Doze mode
                    val info = AlarmManager.AlarmClockInfo(alarmEntity.time.time, alarmIntent)
                    alarmManager.setAlarmClock(info, alarmIntent)

                    // TODO: set upcoming notification, (hosted on flutter)
                }

                // TODO: update sql database time of item(hosted on flutter)

                // Stop the service + FullscreenActivity
                val serviceIntent = Intent(context, AlarmService::class.java)
                context.stopService(serviceIntent)
                val finishIntent = Intent("com.mindr.alarm.ACTION_FINISH")
                context.sendBroadcast(finishIntent)
            }
            else -> {
                // Remove the upcoming notification
                notificationManager.cancel(alarmEntity.id * 1234)

                // Start the service
                val intentToAlarmService = Intent(context, AlarmService::class.java)
                intentToAlarmService.putExtra("EXTRA_ALARM_JSON", alarmJson)
                ContextCompat.startForegroundService(context, intentToAlarmService)
            }
        }
    }
}
