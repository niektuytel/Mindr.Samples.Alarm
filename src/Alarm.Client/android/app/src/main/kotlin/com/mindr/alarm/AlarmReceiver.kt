package com.mindr.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.workDataOf
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.mindr.alarm.models.AlarmEntity
import com.mindr.alarm.utils.DateTimeUtils
import java.util.Calendar
import java.util.Date

class AlarmReceiver : BroadcastReceiver() {
    private val gson = Gson()
    private val mapType = object: TypeToken<Map<String, Any>>() {}.type
    private lateinit var alarmJson: String;
    private lateinit var alarmEntity: AlarmEntity;

    override fun onReceive(context: Context, intent: Intent) {
        alarmJson = intent.getStringExtra("EXTRA_ALARM_JSON")!!
        val alarmMap: Map<String, Any> = gson.fromJson(alarmJson, mapType)
        alarmEntity = AlarmEntity.fromMap(alarmMap)

        println("AlarmReceiver: action: ${intent.action} alarmJson: $alarmJson")
        when (intent.action) {
            "upcoming alarm" -> {
                val data = workDataOf("INTENT_ACTION" to intent.action, "EXTRA_ALARM_JSON" to alarmJson)
                val workRequest = OneTimeWorkRequestBuilder<AlarmWorker>()
                        .setInputData(data)
                        .build()

                WorkManager.getInstance(context).enqueue(workRequest)
            }
            "trigger alarm" -> {
                val intentToAlarmService = Intent(context, TriggerAlarmService::class.java)
                intentToAlarmService.putExtra("EXTRA_ALARM_JSON", alarmJson)
                ContextCompat.startForegroundService(context, intentToAlarmService)
            }
            "SNOOZE_ACTION" -> {
                // stop trigger + related alarm
                MainActivity.stopTriggerService(context, alarmEntity.id)
                MainActivity.stopNotification(context, alarmEntity.id)

                // Set a alarm over 10 minutes
                alarmEntity.time.add(Calendar.MINUTE, 10) // Add 10 minutes
                MainActivity.setAlarmService(context, alarmEntity.time, "trigger alarm", alarmEntity)

                // show snoozed notification
                alarmJson = gson.toJson(alarmEntity.toMap())
                val data = workDataOf("INTENT_ACTION" to intent.action, "EXTRA_ALARM_JSON" to alarmJson)
                val workRequest = OneTimeWorkRequestBuilder<AlarmWorker>()
                        .setInputData(data)
                        .build()

                WorkManager.getInstance(context).enqueue(workRequest)
            }
            "DISMISS_ACTION" -> {
                // stop trigger + related alarm
                MainActivity.stopTriggerService(context, alarmEntity.id)
                MainActivity.stopNotification(context, alarmEntity.id)

                // Set a new notification if scheduledDays are set
                if (alarmEntity.scheduledDays.isNotEmpty()) {
                    // Update alarm to next time
                    alarmEntity = DateTimeUtils.setNextItemTime(alarmEntity, alarmEntity.time)
                    alarmJson = gson.toJson(alarmEntity.toMap())

                    MainActivity.scheduleAlarm(context, alarmJson)
                }
            }
        }
    }

}
