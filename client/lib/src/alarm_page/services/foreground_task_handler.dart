import 'dart:async';
import 'dart:isolate';

import 'package:client/src/services/shared_preferences_service.dart';
import 'package:client/src/widgets/alarm_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';

import '../../../main.dart';

class AlarmForegroundTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  int _eventCount = 0;
  int _alarmItemId = 0;

  // Called when the task is started.
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;

    // Sound
    final audioPlayer = AudioPlayer();
    Duration? audioDuration = await audioPlayer.setAsset('assets/marimba.mp3');
    audioPlayer.setLoopMode(LoopMode.all);
    audioPlayer.play();
    Timer(Duration(minutes: 20), () async {
      // Stop playback after 20 minutes
      await audioPlayer.stop();
      await AudioPlayer.clearAssetCache();
    });

    // You can use the getData function to get the stored data.
    final alarmItemId =
        await FlutterForegroundTask.getData<String>(key: 'alarmItemId');
    print('alarmItemId: $alarmItemId');
  }

  // Called every [interval] milliseconds in [ForegroundTaskOptions].
  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    FlutterForegroundTask.updateService(
      notificationTitle: 'MyTaskHandler',
      notificationText: 'eventCount: $_eventCount',
    );

    // Vibrate 1x
    Vibration.vibrate();

    // Send data to the main isolate.
    sendPort?.send(_eventCount);

    _eventCount++;
  }

  // Called when the notification button on the Android platform is pressed.
  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    print('onDestroy');
  }

  // Called when the notification button on the Android platform is pressed.
  @override
  void onNotificationButtonPressed(String id) {
    print('onNotificationButtonPressed >> $id');
  }

  // Called when the notification itself on the Android platform is pressed.
  //
  // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
  // this function to be called.
  @override
  void onNotificationPressed() async {
    // You can use the getData function to get the stored data.
    final alarmItemId =
        await FlutterForegroundTask.getData<int>(key: 'alarmItemId');

    // This is needed to show the AlarmScreen when the app is in the foreground
    // await SharedPreferencesService.setActiveAlarmItemId(alarmId);
    navigatorKey.currentState!
        .push(MaterialPageRoute(builder: (_) => AlarmScreen(alarmItemId)));
  }
}
