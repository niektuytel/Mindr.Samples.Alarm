package com.mindr.alarm

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec

class MainActivity: FlutterActivity() {

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        // Return the cached FlutterEngine from the CustomApplication setup
        return FlutterEngineCache.getInstance().get("mindr_flutter_engine_id")
    }
//
//    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
//        val taskQueue =
//                flutterPluginBinding.binaryMessenger.makeBackgroundTaskQueue()
//        channel = MethodChannel(flutterPluginBinding.binaryMessenger,
//                "com.example.foo",
//                StandardMethodCodec.INSTANCE,
//                taskQueue)
//        channel.setMethodCallHandler(this)
//    }
}
