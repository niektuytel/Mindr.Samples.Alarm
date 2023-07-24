import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mindr.alarm/src/services/shared_preferences_service.dart';
import 'package:mindr.alarm/src/services/sqflite_service.dart';
import 'package:vibration/vibration.dart';

import '../alarm_page/alarm_screen.dart';
import '../models/alarm_item_view.dart';
import '../utils/datatimeUtils.dart';
import 'alarm_service.dart';
import 'alarm_handler.dart';

// The callback function should always be a top-level function.
@pragma('vm:entry-point')
void handleAlarmTriggeredTask() {
  FlutterForegroundTask.setTaskHandler(AlarmForegroundTriggeredTaskHandler());
  // // The setTaskHandler function must be called to handle the task in the background.
  // FlutterForegroundTask.setTaskHandler(AlarmTaskHandler());
}

// @pragma('vm:entry-point')
Future<bool> showNotification(int id) async {
  print('Alarm triggered! id: $id');
  SqfliteService dbHelper = SqfliteService();
  AlarmItemView? alarmItem = await dbHelper.getAlarm(id);

  if (alarmItem == null || alarmItem.enabled == false) {
    return false;
  }

  // // cancel the upcoming alarm notification
  // await localNotificationsPlugin.cancel(alarmItem.id);
  // await localNotificationsPlugin.cancel(alarmItem.id * 1234);

  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      id: id,
      channelId: 'triggered_alarm',
      channelName: 'Alarm',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
      buttons: [
        const NotificationButton(
          id: 'snooze',
          text: 'Snooze',
          textColor: Color.fromARGB(255, 0, 0, 0),
        ),
        const NotificationButton(
          id: 'dismiss',
          text: 'Stop',
          textColor: Color.fromARGB(255, 0, 0, 0),
        ),
      ],
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: const ForegroundTaskOptions(
      interval: 5000,
      isOnceEvent: false,
      autoRunOnBoot: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

  String body = alarmItem.label.isEmpty
      ? DateTimeUtils.formatDateTime(alarmItem.time)
      : '${DateTimeUtils.formatDateTime(alarmItem.time)} - ${alarmItem.label}';

  // You can save data using the saveData function.
  await FlutterForegroundTask.saveData(key: 'alarmItemId', value: id);
  await SharedPreferencesService.setActiveAlarmItemId(id);
  return FlutterForegroundTask.startService(
    notificationTitle: 'Alarm',
    notificationText: body,
    callback: handleAlarmTriggeredTask,
  );
}

class AlarmForegroundTriggeredTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  int _eventCount = 0;
  int _alarmItemId = 0;

  // Called when the task is started.
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;
    _alarmItemId =
        await FlutterForegroundTask.getData<int>(key: 'alarmItemId') as int;

    FlutterForegroundTask.wakeUpScreen();
    FlutterForegroundTask.setOnLockScreenVisibility(true);

    // Sound
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      androidAudioAttributes: AndroidAudioAttributes(
        usage: AndroidAudioUsage.alarm,
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));

    final audioPlayer = AudioPlayer();

    try {
      await audioPlayer.setAudioSource(
        AudioSource.asset('assets/marimba.mp3'),
      );
    } catch (e) {
      // catch load errors: 404, invalid url ...
      print("An error occurred $e");
    }

    await audioPlayer.setLoopMode(LoopMode.all);
    await audioPlayer.play();

    Timer(Duration(minutes: 20), () async {
      // Stop playback after 20 minutes
      await audioPlayer.stop();
    });

    // // launch app
    // FlutterForegroundTask.launchApp('${AlarmScreen.routeName}/$_alarmItemId');
  }

  // Called every [interval] milliseconds in [ForegroundTaskOptions].
  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    // FlutterForegroundTask.updateService(
    //   notificationTitle: 'Alarm',
    //   notificationText: 'eventCount: $_eventCount',
    // );

    // Vibrate 1x
    await Vibration.vibrate();

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
  Future<void> onNotificationButtonPressed(String actionId) async {
    print('onNotificationButtonPressed >> $actionId');

    // This is called when a notification or its action is tapped.
    if (actionId == 'snooze') {
      await AlarmHandler.snoozeAlarm(_alarmItemId);
    } else if (actionId == 'dismiss') {
      await AlarmService.stopAlarm(_alarmItemId);
    }
  }

  // Called when the notification itself on the Android platform is pressed.
  //
  // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
  // this function to be called.
  @override
  void onNotificationPressed() async {
    print('onNotificationPressed >> $_alarmItemId');
    FlutterForegroundTask.launchApp('${AlarmScreen.routeName}/$_alarmItemId');
  }
}
