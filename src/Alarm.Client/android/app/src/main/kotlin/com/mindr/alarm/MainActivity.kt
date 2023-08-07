package com.mindr.alarm

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.mindr.alarm/alarm_trigger"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val alarmService = AlarmService.getInstance(applicationContext)
            when (call.method) {
                "scheduleAlarm" -> {
                    val alarm: String = call.argument("alarm") ?: ""
                    alarmService.scheduleAlarm(alarm)
                    result.success(null)
                }
                "removeAlarm" -> {
                    val id = call.argument<String>("id")?.toInt() ?: -1
                    alarmService.stopTriggerService(id)
                    alarmService.stopNotification(id)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }


}
