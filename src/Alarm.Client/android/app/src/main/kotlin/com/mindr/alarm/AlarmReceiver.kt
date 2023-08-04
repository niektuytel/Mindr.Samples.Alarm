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
import com.mindr.alarm.MainActivity.Companion.REQUEST_CODE
import com.mindr.alarm.models.AlarmEntity
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class AlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        println("AlarmReceiver.action: $action")

        // Retrieve the alarmJson from the intent extras
        val gson = Gson()
        val alarmJson = intent.getStringExtra("EXTRA_ALARM_JSON")
        val alarmEntity = gson.fromJson(alarmJson, AlarmEntity::class.java)
        println("AlarmReceiver.alarmJson: $alarmJson")

        // Create a notification manager
        val notificationManager = NotificationManagerCompat.from(context)

        when (action) {
//            "SNOOZE_ACTION" -> {
//                // TODO set new notification 'Upcoming notification' with dismiss button to dismiss sound
//                // TODO remove current Foreground service+notification + set new one over 10 minutes
//            }
//            "DISMISS_ACTION" -> {
//                // TODO remove current Foreground service+notification + set new one when scheduledays are used.
//                // TODO set new notification 'Upcoming notification' with dismiss button to dismiss sound wen has an schedule days set
//            }
            "SNOOZE_ACTION" -> {
                // Dismiss the current notification
                notificationManager.cancel(alarmEntity.id)


//                // Set a new alarm over 10 minutes
//                // You may want to adjust this according to your needs
//                val snoozeIntent = Intent(context, AlarmService::class.java)
//                snoozeIntent.putExtra("EXTRA_ALARM_JSON", alarmJson)
//                ContextCompat.startForegroundService(context, snoozeIntent)

                // TODO: update sql database time of item
                
                // Stop the service
                val serviceIntent = Intent(context, AlarmService::class.java)
                context.stopService(serviceIntent)
            }
            "DISMISS_ACTION" -> {
                // Remove current notification
                notificationManager.cancel(alarmEntity.id)

                // Set a new notification if scheduledDays are set
                if (alarmEntity.scheduledDays.isNotEmpty()) {
                    val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                    val alarmIntent = Intent(context, AlarmReceiver::class.java).let { intent ->
                        intent.putExtra("EXTRA_ALARM_JSON", alarmJson)  // Pass the alarmJson as an extra
                        PendingIntent.getBroadcast(context, REQUEST_CODE, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE)
                    }

                    // AlarmManager.AlarmClockInfo is used to set an exact alarm that is allowed to interrupt Doze mode
                    val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US)
                    val date: Date = format.parse(alarmEntity.time) as Date
                    val triggerTime = date.time // Convert Date to milliseconds

                    val info = AlarmManager.AlarmClockInfo(triggerTime, alarmIntent)
                    alarmManager.setAlarmClock(info, alarmIntent)

                    // TODO: set upcoming notification, try to do this from the flutter part of code.
                }

                // TODO: update sql database time of item

                // Stop the service
                val serviceIntent = Intent(context, AlarmService::class.java)
                context.stopService(serviceIntent)
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
