package com.mindr.alarm

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
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

    val upcomingChannelId = "com.mindr.alarm/upcoming_alarms_channel_id"
    private val gson = Gson()
    private val mapType = object: TypeToken<Map<String, Any>>() {}.type
    private lateinit var alarmJson: String;
    private lateinit var alarmEntity: AlarmEntity;


    private fun createUpcomingNotification(context: Context): Notification {
        // Create a "dismiss" action
        val dismissIntent = Intent(context, AlarmReceiver::class.java).apply {
            this.action = "DISMISS_ACTION"
            this.putExtra("EXTRA_ALARM_JSON", alarmJson)
        }

        val dismissPendingIntent: PendingIntent =
                PendingIntent.getBroadcast(context, 0, dismissIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE)

        val dismissAction = NotificationCompat.Action.Builder(0, "Dismiss", dismissPendingIntent).build()

        return NotificationCompat.Builder(context, upcomingChannelId)
                .setSmallIcon(R.drawable.launch_background)
                .setContentTitle("Upcoming alarm")
                .setContentText(getBody())
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setOngoing(true)
                .setAutoCancel(false)
                .addAction(dismissAction)
                .build()
    }

    override fun onReceive(context: Context, intent: Intent) {
        // Retrieve the alarmJson from the intent extras
        alarmJson = intent.getStringExtra("EXTRA_ALARM_JSON")!!
        var alarmMap: Map<String, Any> = gson.fromJson(alarmJson, mapType)
        alarmEntity = AlarmEntity.fromMap(alarmMap)

        val notificationManager = NotificationManagerCompat.from(context)
        println("AlarmReceiver: action: ${intent.action} alarmJson: $alarmJson")
        when (intent.action) {
            "upcoming alarm" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val channel = NotificationChannel(
                            upcomingChannelId,
                            "Upcoming alarms",
                            NotificationManager.IMPORTANCE_HIGH
                    )
                    val manager = context.getSystemService(NotificationManager::class.java)
                    manager?.createNotificationChannel(channel)
                }

                val notification = createUpcomingNotification(context)
                notificationManager.notify(alarmEntity.id, notification)
            }
            "trigger alarm" -> {
                //                // Remove the upcoming notification, not needed as now the upcoming is using the same id
                //                val notificationManager = NotificationManagerCompat.from(context)
                //                notificationManager.cancel(alarmEntity.id * 1234)

                // Start the service
                val intentToAlarmService = Intent(context, AlarmService::class.java)
                intentToAlarmService.putExtra("EXTRA_ALARM_JSON", alarmJson)
                ContextCompat.startForegroundService(context, intentToAlarmService)
            }

            "SNOOZE_ACTION" -> {
                // Set a new alarm over 10 minutes
                val tenMinutesInMilliseconds = 10 * 60 * 1000
                alarmEntity.time = Date(alarmEntity.time.time + tenMinutesInMilliseconds)
                alarmMap = alarmEntity.toMap()
                alarmJson = gson.toJson(alarmMap)
                MainActivity.scheduleAlarm(context, alarmJson)

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

                // Stop the notification +  service + FullscreenActivity
                notificationManager.cancel(alarmEntity.id)
                val serviceIntent = Intent(context, AlarmService::class.java)
                context.stopService(serviceIntent)
                val finishIntent = Intent("com.mindr.alarm.ACTION_FINISH")
                context.sendBroadcast(finishIntent)
            }
        }
    }

    private fun getBody(): String {
        // Convert ISO 8601 string to Date
        val sdf = SimpleDateFormat("EEE h:mm a", Locale.US)
        val date = sdf.format(alarmEntity.time)

        return if (alarmEntity.label.isNotEmpty()) {
            "$date - ${alarmEntity.label}"
        } else {
            date
        }
    }
}
