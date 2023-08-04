package com.mindr.alarm

import android.annotation.SuppressLint
import android.app.KeyguardManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.MediaPlayer
import android.os.Build
import android.os.Bundle
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.RelativeLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import com.google.gson.Gson
import com.jakewharton.threetenabp.AndroidThreeTen
import com.mindr.alarm.AlarmService
import com.mindr.alarm.R
import com.mindr.alarm.models.AlarmEntity
import java.time.LocalDateTime
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter

class FullscreenActivity : AppCompatActivity() {
    private var alarmEntity: AlarmEntity? = null
    private var alarmJson: String? = null
    private val dismissReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == "com.mindr.alarm.action.DISMISS") {
                finish()
            }
        }
    }

    @SuppressLint("ClickableViewAccessibility")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        AndroidThreeTen.init(this)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            keyguardManager.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }

        val gson = Gson()
        alarmJson = intent.getStringExtra("EXTRA_ALARM_JSON")
        alarmEntity = gson.fromJson(alarmJson, AlarmEntity::class.java)
        println("FullscreenActivity.alarmJson: $alarmJson")

        setContentView(R.layout.activity_fullscreen)

        // Enable immersive sticky fullscreen mode
        WindowCompat.setDecorFitsSystemWindows(window, false)
        val controller = WindowInsetsControllerCompat(window, window.decorView)
        controller.hide(WindowInsetsCompat.Type.statusBars() or WindowInsetsCompat.Type.navigationBars())

        val tvCurrentTime: TextView = findViewById(R.id.tv_current_time)
        val alarmLabel: TextView = findViewById(R.id.alarm_label)
        val snoozeButton: Button = findViewById(R.id.btn_snooze)
        val dismissButton: Button = findViewById(R.id.btn_dismiss)

        // Display the current time
        val formatter = org.threeten.bp.format.DateTimeFormatter.ofPattern("hh:mm")
        tvCurrentTime.text = org.threeten.bp.LocalDateTime.now().format(formatter)

        // Display alarm label
        alarmLabel.text = alarmEntity?.label

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

        snoozeButton.setOnClickListener {
            try {
                snoozePendingIntent.send()
            } catch (e: PendingIntent.CanceledException) {
                e.printStackTrace()
            }
        }

        dismissButton.setOnClickListener {
            try {
                dismissPendingIntent.send()
            } catch (e: PendingIntent.CanceledException) {
                e.printStackTrace()
            }
        }

        val intentFilter = IntentFilter()
        intentFilter.addAction("com.mindr.alarm.action.DISMISS")
        registerReceiver(dismissReceiver, intentFilter)


        val mainLayout: RelativeLayout = findViewById(R.id.main_layout)
        mainLayout.setOnTouchListener { v, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    // Check if the touch event is specifically on the dismiss button
                    if (!isPointInsideView(event.rawX, event.rawY, dismissButton)) {
                        snoozeButton.performClick()
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    v.performClick()
                    true
                }
                else -> false
            }
        }

    }


    // Function to check if a given point (x, y) is inside a given view
    private fun isPointInsideView(x: Float, y: Float, view: View): Boolean {
        val location = IntArray(2)
        view.getLocationOnScreen(location)
        val viewX = location[0]
        val viewY = location[1]

        // point is inside view bounds
        return (x > viewX && x < viewX + view.width && y > viewY && y < viewY + view.height)
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(dismissReceiver)
    }

}
