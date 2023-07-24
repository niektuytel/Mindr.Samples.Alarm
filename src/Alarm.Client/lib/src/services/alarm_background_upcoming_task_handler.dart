import 'dart:async';
import 'dart:isolate';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';

import '../alarm_page/alarm_screen.dart';
import 'alarm_service.dart';
import 'alarm_handler.dart';

class AlarmBackgroundUpcomingTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  int _eventCount = 0;
  int _alarmItemId = 0;

  // Called when the task is started.
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;
    _alarmItemId =
        await FlutterForegroundTask.getData<int>(key: 'alarmItemId') as int;
  }

  // Called every [interval] milliseconds in [ForegroundTaskOptions].
  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {}

  // Called when the notification button on the Android platform is pressed.
  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {}

  @override
  Future<void> onNotificationButtonPressed(String actionId) async {
    print('onNotificationButtonPressed >> $actionId');

    // This is called when a notification or its action is tapped.
    if (actionId == 'dismiss') {
      await AlarmService.stopAlarm(_alarmItemId);
    }
  }

  @override
  void onNotificationPressed() async {
    print('onNotificationPressed >> $_alarmItemId');
    FlutterForegroundTask.launchApp('${AlarmScreen.routeName}/$_alarmItemId');
  }
}
