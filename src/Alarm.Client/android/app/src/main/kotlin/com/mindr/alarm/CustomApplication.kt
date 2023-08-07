package com.mindr.alarm

import android.content.Context
import androidx.multidex.MultiDex
import io.flutter.app.FlutterApplication
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugins.GeneratedPluginRegistrant

class CustomApplication : FlutterApplication() {
    lateinit var flutterEngine: FlutterEngine

    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        MultiDex.install(this)
    }
    override fun onCreate() {
        super.onCreate()  // Move this up to ensure the application context is properly initialized

        // Initialize Flutter using FlutterLoader
        val flutterLoader = FlutterLoader()
        flutterLoader.startInitialization(this)
        flutterLoader.ensureInitializationComplete(this, null)

        flutterEngine = FlutterEngine(applicationContext)
        flutterEngine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
        )

        GeneratedPluginRegistrant.registerWith(flutterEngine)
        FlutterEngineCache
                .getInstance()
                .put("mindr_flutter_engine_id", flutterEngine)

        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.mindr.alarm/alarm_trigger")
        methodChannel.setMethodCallHandler(AlarmMethodCallHandler(applicationContext))
    }

}
