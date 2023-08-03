package com.mindr.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {

        // Start the service first
        val intentToAlarmService = Intent(context, AlarmService::class.java)
        ContextCompat.startForegroundService(context, intentToAlarmService)

        // Then start the activity
        val intentToFullScreenActivity = Intent(context, FullscreenActivity::class.java)
        intentToFullScreenActivity.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intentToFullScreenActivity)
    }
}

