package com.mindr.alarm

import android.app.KeyguardManager
import android.content.Context
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.content.Intent
import android.os.Build
import android.view.WindowManager
import android.widget.Button
import android.content.BroadcastReceiver
import android.content.IntentFilter
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat

class FullscreenActivity : AppCompatActivity() {

    private val dismissReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == "com.mindr.alarm.action.DISMISS") {
                finish()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

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

        setContentView(R.layout.activity_fullscreen)

        // enable immersive sticky fullscreen mode
        WindowCompat.setDecorFitsSystemWindows(window, false)
        val controller = WindowInsetsControllerCompat(window, window.decorView)
        controller.hide(WindowInsetsCompat.Type.statusBars() or WindowInsetsCompat.Type.navigationBars())

        val snoozeButton: Button = findViewById(R.id.btn_snooze)
        val dismissButton: Button = findViewById(R.id.btn_dismiss)

        snoozeButton.setOnClickListener {
            // handle snooze action
        }

        dismissButton.setOnClickListener {
            // handle dismiss action
            val intentToAlarmService = Intent(this, AlarmService::class.java)
            stopService(intentToAlarmService)
        }

        val intentFilter = IntentFilter()
        intentFilter.addAction("com.mindr.alarm.action.DISMISS")
        registerReceiver(dismissReceiver, intentFilter)
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(dismissReceiver)
    }
}
//package com.mindr.alarm
//
//import io.flutter.embedding.android.FlutterActivity
//import io.flutter.embedding.engine.FlutterEngine
//import io.flutter.embedding.engine.dart.DartExecutor
//import io.flutter.view.FlutterMain
//
//class FullscreenActivity : FlutterActivity() {// : AppCompatActivity() {
//override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//    val entrypoint = DartExecutor.DartEntrypoint(
//            FlutterMain.findAppBundlePath(),
//            "/alarm_screens/1"
//    )
//
//    flutterEngine.dartExecutor.executeDartEntrypoint(entrypoint)
//}
//
//    override fun shouldAttachEngineToActivity(): Boolean {
//        // Control whether the FlutterEngine should be attached to this Activity.
//        return true
//    }
//}

