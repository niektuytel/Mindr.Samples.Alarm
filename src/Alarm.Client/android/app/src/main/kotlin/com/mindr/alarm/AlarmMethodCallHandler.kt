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
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class AlarmMethodCallHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    private val alarmService = AlarmService.getInstance(context)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        println("Method called: ${call.method}")
        when (call.method) {
            "scheduleAlarm" -> {
                val alarmJson: String = call.argument("alarm") ?: ""
                alarmService.scheduleAlarm(alarmJson)
                result.success(null)
            }
            "removeAlarm" -> {
                val id = call.argument<Int>("id") ?: -1
                alarmService.stopTriggerService(id)
                alarmService.stopNotification(id)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}
