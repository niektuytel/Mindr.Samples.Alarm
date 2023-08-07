package com.mindr.alarm
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.Worker
import androidx.work.WorkerParameters
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.mindr.alarm.models.AlarmEntity
import com.mindr.alarm.utils.DateTimeUtils
import java.text.SimpleDateFormat
import java.util.Locale

class AlarmWorker(appContext: Context, workerParams: WorkerParameters)
    : Worker(appContext, workerParams) {

    val upcomingChannelId = "com.mindr.alarm/upcoming_alarms_channel_id"
    val snoozedChannelId = "com.mindr.alarm/snoozing_alarms_channel_id"
    private val gson = Gson()
    private val mapType = object: TypeToken<Map<String, Any>>() {}.type
    private lateinit var alarmJson: String;
    private lateinit var alarmEntity: AlarmEntity;

    override fun doWork(): Result {
        val action = inputData.getString("INTENT_ACTION") ?: return Result.failure()
        alarmJson = inputData.getString("EXTRA_ALARM_JSON") ?: return Result.failure()
        println("AlarmWorker: action: $action alarmJson: $alarmJson")

        val alarmMap: Map<String, Any> = gson.fromJson(alarmJson, mapType)
        alarmEntity = AlarmEntity.fromMap(alarmMap)

        notifyNotification(action, applicationContext)

        // Indicate whether the task finished successfully with the Result
        return Result.success()
    }

    private fun notifyNotification(action: String, context: Context) {
        val notificationManager = NotificationManagerCompat.from(applicationContext)
        when (action) {
            "upcoming alarm" -> {
                initializeUpcomingNotification()
                val notification = createUpcomingNotification(context)
                notificationManager.notify(alarmEntity.id, notification)
            }
            "SNOOZE_ACTION" -> {
                initializeSnoozedNotification()
                val notification = createSnoozedNotification(context)
                notificationManager.notify(alarmEntity.id, notification)
            }
            else -> {
                throw NotImplementedError("unknown action: $action")
            }
        }
    }

    private fun initializeUpcomingNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                    upcomingChannelId,
                    "Upcoming alarms",
                    NotificationManager.IMPORTANCE_HIGH
            )
            val manager = applicationContext.getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun initializeSnoozedNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                    snoozedChannelId,
                    "Snoozing alarms",
                    NotificationManager.IMPORTANCE_HIGH
            )
            val manager = applicationContext.getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

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
                .setContentText(DateTimeUtils.getBody(alarmEntity))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setOngoing(true)
                .setAutoCancel(false)
                .addAction(dismissAction)
                .build()
    }

    private fun createSnoozedNotification(context: Context): Notification {
        // Create a "dismiss" action
        val dismissIntent = Intent(context, AlarmReceiver::class.java).apply {
            this.action = "DISMISS_ACTION"
            this.putExtra("EXTRA_ALARM_JSON", alarmJson)
        }

        val dismissPendingIntent: PendingIntent =
                PendingIntent.getBroadcast(context, 0, dismissIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE)

        val dismissAction = NotificationCompat.Action.Builder(0, "Dismiss", dismissPendingIntent).build()

        return NotificationCompat.Builder(context, snoozedChannelId)
                .setSmallIcon(R.drawable.launch_background)
                .setContentTitle("Snoozed alarm")
                .setContentText(DateTimeUtils.getBody(alarmEntity))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setOngoing(true)
                .setAutoCancel(false)
                .addAction(dismissAction)
                .build()
    }


}
