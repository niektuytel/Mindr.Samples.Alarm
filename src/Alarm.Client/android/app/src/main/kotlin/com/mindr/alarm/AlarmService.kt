package com.mindr.alarm

import android.app.*
import android.content.Intent
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.google.gson.Gson
import com.mindr.alarm.models.AlarmEntity
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class AlarmService : Service() {
    private var alarmEntity: AlarmEntity? = null
    private var alarmJson: String? = null
    private var mediaPlayer: MediaPlayer? = null
    private val CHANNEL_ID = "com.mindr.alarm/firing_alarm_service_channel"

    override fun onCreate() {
        super.onCreate()
        initializeNotificationChannel()

        // Then start the activity
        val intentToFullScreenActivity = Intent(this, FullscreenActivity::class.java)
        intentToFullScreenActivity.putExtra("EXTRA_ALARM_JSON", alarmJson)
        intentToFullScreenActivity.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        this.startActivity(intentToFullScreenActivity)
    }


    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        val gson = Gson()
        alarmJson = intent.getStringExtra("EXTRA_ALARM_JSON")
        alarmEntity = gson.fromJson(alarmJson, AlarmEntity::class.java)
        println("AlarmService.alarmJson: $alarmJson")

        mediaPlayer = MediaPlayer.create(this, R.raw.argon) // Replace argon with your sound file
        mediaPlayer?.isLooping = true
        mediaPlayer?.start()

        // Create notification here
        val notification = createNotification()
        startForeground(alarmEntity?.id!!, notification)

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
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
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

        val snoozeAction = NotificationCompat.Action.Builder(0, "Snooze", snoozePendingIntent).build()
        val dismissAction = NotificationCompat.Action.Builder(0, "Stop", dismissPendingIntent).build()
        return NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Alarm")
                .setContentText(getBody())
                .setSmallIcon(R.drawable.launch_background)
                .setContentIntent(pendingIntent)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .addAction(snoozeAction)
                .addAction(dismissAction)
                .build()

    }

    fun formatDateTimeAsDay(dateTime: Date): String {
        val sdf = SimpleDateFormat("EEE h:mm a")
        return sdf.format(dateTime)
    }
    private fun getBody(): String {
        // Convert ISO 8601 string to Date
        val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US)
        val date: Date = format.parse(alarmEntity?.time!!) as Date

        return if (alarmEntity?.label?.isEmpty() == false) {
            "${formatDateTimeAsDay(date)} - ${alarmEntity?.label}"
        } else {
            formatDateTimeAsDay(date)
        }
    }
}
