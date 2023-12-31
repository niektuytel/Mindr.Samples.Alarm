package com.mindr.alarm

import android.app.*
import android.content.Intent
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.mindr.alarm.models.AlarmEntity
import com.mindr.alarm.utils.DateTimeUtils
import java.text.SimpleDateFormat
import java.util.Locale

class TriggerAlarmService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private val CHANNEL_ID = "com.mindr.alarm/firing_alarms_channel_id"

    private val gson = Gson()
    private val mapType = object: TypeToken<Map<String, Any>>() {}.type
    private lateinit var alarmJson: String;
    private lateinit var alarmEntity: AlarmEntity;

    override fun onCreate() {
        super.onCreate()
        initializeNotificationChannel()

    }


    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        alarmJson = intent.getStringExtra("EXTRA_ALARM_JSON")!!
        val alarmMap: Map<String, Any> = gson.fromJson(alarmJson, mapType)
        alarmEntity = AlarmEntity.fromMap(alarmMap)
        println("TriggerAlarmService.alarmJson: $alarmJson")

        mediaPlayer = MediaPlayer.create(this, R.raw.argon) // Replace argon with your sound file
        mediaPlayer?.isLooping = true
        mediaPlayer?.start()

        // Create notification here
        val notification = createNotification()
        startForeground(alarmEntity.id, notification)

        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        mediaPlayer?.stop()
    }

    override fun onBind(intent: Intent): IBinder? {
        return null
    }

    private fun initializeNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                    CHANNEL_ID,
                    "Firing alarms",
                    NotificationManager.IMPORTANCE_HIGH
            )
            channel.lockscreenVisibility = Notification.VISIBILITY_PUBLIC // Ensure visibility on lock screen
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val snoozeIntent = Intent(this, AlarmReceiver::class.java).apply {
            action = "SNOOZE_ACTION"
            putExtra("EXTRA_ALARM_JSON", alarmJson)
        }
        val dismissIntent = Intent(this, AlarmReceiver::class.java).apply {
            action = "DISMISS_ACTION"
            putExtra("EXTRA_ALARM_JSON", alarmJson)
        }
        val snoozePendingIntent: PendingIntent = PendingIntent.getBroadcast(this, 0, snoozeIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val dismissPendingIntent: PendingIntent = PendingIntent.getBroadcast(this, 1, dismissIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)

        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(this, 0, notificationIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val fullscreenIntent = Intent(this, TriggerAlarmActivity::class.java)
        fullscreenIntent.putExtra("EXTRA_ALARM_JSON", alarmJson)
        fullscreenIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        val fullscreenPendingIntent = PendingIntent.getActivity(this, 0, fullscreenIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)


        val snoozeAction = NotificationCompat.Action.Builder(0, "Snooze", snoozePendingIntent).build()
        val dismissAction = NotificationCompat.Action.Builder(0, "Stop", dismissPendingIntent).build()
        return NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Alarm")
                .setContentText(DateTimeUtils.getBody(alarmEntity))
                .setSmallIcon(R.drawable.ic_alarm)
                .setContentIntent(pendingIntent)
                .setFullScreenIntent(fullscreenPendingIntent, true)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setOngoing(true)
                .setAutoCancel(false)
                .addAction(snoozeAction)
                .addAction(dismissAction)
                .build()

    }

}
