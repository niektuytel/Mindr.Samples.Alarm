import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:alarm/alarm.dart';
import 'package:audio_session/audio_session.dart';
import 'package:client/src/models/alarm_item_view.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:client/src/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import '../../../main.dart';
import '../models/alarm_brief_item.dart';
import 'alarm_screen.dart';
import 'package:intl/intl.dart';
import '../services/sqflite_service.dart';
import 'alarm_list_page.dart';

final FlutterLocalNotificationsPlugin localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// This must be a top-level function, outside of any class.
@pragma('vm:entry-point')
void notificationHandler(NotificationResponse response) async {
  print(
      'Notification handler id:${response.id} payload:${response.payload!} action:${response.actionId}');

  int alarmItemId = jsonDecode(response.payload!)['id'];
  bool? openAlarmOnClick = jsonDecode(response.payload!)['open_alarm_onclick'];

  // This is called when a notification or its action is tapped.
  if (response.actionId != null) {
    if (response.actionId == 'snooze') {
      await AlarmReceiver.snoozeAlarm(alarmItemId);
    } else if (response.actionId == 'dismiss') {
      await AlarmReceiver.stopAlarm(alarmItemId);
    }

    return;
  }

  if (openAlarmOnClick == true) {
    // Open the alarm screen, when app is in background.
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!
          .pushNamed('${AlarmScreen.routeName}/$alarmItemId');
    }
  }
}

// The callback function should always be a top-level function.
@pragma('vm:entry-point')
void alarmHandler() {
  FlutterForegroundTask.setTaskHandler(AlarmForegroundTaskHandler());
  // // The setTaskHandler function must be called to handle the task in the background.
  // FlutterForegroundTask.setTaskHandler(AlarmTaskHandler());
}

class AlarmReceiver {
  static void init(BuildContext context) async {
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: notificationHandler,
      onDidReceiveBackgroundNotificationResponse: notificationHandler,
    );
  }

  static Future<void> showUpcomingNotification(int id) async {
    int itemId = (id / 1234).truncate();

    SqfliteService dbHelper = SqfliteService();
    AlarmItemView? alarmItem = await dbHelper.getAlarm(itemId);

    if (alarmItem == null || alarmItem.enabled == false) {
      return;
    }

    // Check if current day is in the scheduledDays list
    if (alarmItem.scheduledDays.isNotEmpty) {
      int currentDay =
          DateTime.now().weekday; // Get the current day of the week

      if (!alarmItem.scheduledDays.contains(currentDay)) {
        print('Today is not a scheduled day for this alarm');
        return; // Return early if today is not a scheduled day
      }
    }

    print('Upcoming Alarm triggered!');
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      (id).toString(),
      'Upcoming Alarm',
      importance: Importance.high,
      priority: Priority.defaultPriority,
      showWhen: true,
      styleInformation: DefaultStyleInformation(true, true),
      ongoing: true, // Makes the notification persistent.
      autoCancel:
          false, // Prevents the notification from being dismissed when user taps on it.
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('dismiss', 'Dismiss',
            titleColor: const Color.fromRGBO(28, 56, 134, 1), icon: null)
      ],
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    String body = alarmItem.label.isEmpty
        ? formatDateTime(alarmItem.time)
        : '${formatDateTime(alarmItem.time)} - ${alarmItem.label}';

    // create the payload
    Map<String, dynamic> payloadData = {
      'id': alarmItem.id,
      'open_alarm_onclick': true,
    };

    await SharedPreferencesService.setActiveAlarmItemId(alarmItem.id);
    await localNotificationsPlugin.show(
        id, 'Upcoming alarm', body, platformChannelSpecifics,
        payload: jsonEncode(payloadData));
  }

  static Future<bool> showNotification(int id) async {
    print('Alarm triggered! id: $id');
    SqfliteService dbHelper = SqfliteService();
    AlarmItemView? alarmItem = await dbHelper.getAlarm(id);

    if (alarmItem == null || alarmItem.enabled == false) {
      return false;
    }

    // Check if current day is in the scheduledDays list
    if (alarmItem.scheduledDays.isNotEmpty) {
      int currentDay =
          DateTime.now().weekday; // Get the current day of the week

      if (!alarmItem.scheduledDays.contains(currentDay)) {
        print('Today is not a scheduled day for this alarm');
        return false; // Return early if today is not a scheduled day
      }
    }

    // cancel the upcoming alarm notification
    await localNotificationsPlugin.cancel(alarmItem.id);
    await localNotificationsPlugin.cancel(alarmItem.id * 1234);

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
        ? formatDateTime(alarmItem.time)
        : '${formatDateTime(alarmItem.time)} - ${alarmItem.label}';

    // You can save data using the saveData function.
    await FlutterForegroundTask.saveData(key: 'alarmItemId', value: id);
    await SharedPreferencesService.setActiveAlarmItemId(id);
    return FlutterForegroundTask.startService(
      notificationTitle: 'Alarm',
      notificationText: body,
      callback: alarmHandler,
    );
  }

  static Future<void> stopAlarm(int id) async {
    print('Stop alarm');

    SqfliteService dbHelper = SqfliteService();
    AlarmItemView? alarmItem = await dbHelper.getAlarm(id);

    if (alarmItem == null) {
      return;
    }

    // cancel the upcoming alarm notification and the alarm
    await localNotificationsPlugin.cancel(alarmItem.id * 1234); // upcoming
    await localNotificationsPlugin.cancel(alarmItem.id);
    FlutterForegroundTask.stopService();
    SharedPreferencesService.removeActiveAlarmId();
  }

  static Future<void> snoozeAlarm(int id) async {
    SqfliteService dbHelper = SqfliteService();
    AlarmItemView? alarmItem = await dbHelper.getAlarm(id);

    if (alarmItem == null) {
      return;
    }

    print('Snoozing alarm for 10 minutes...');

    // cancel the upcoming alarm notification and the alarm
    await localNotificationsPlugin.cancel(alarmItem.id * 1234);
    await localNotificationsPlugin.cancel(alarmItem.id);
    FlutterForegroundTask.stopService();

    // show snoozed alarm
    rescheduleAlarmOnSnooze(alarmItem.id);
  }

  static Future<void> scheduleAlarm(AlarmItemView alarm) async {
    int alarmId = alarm.id;
    int preAlarmId = (alarm.id * 1234);
    DateTime alarmTime = alarm.time; //.now().add(Duration(seconds: 5));
    DateTime preAlarmTime = alarm.time.subtract(Duration(hours: 2));

    if (alarm.scheduledDays.isEmpty) {
      // only once
      await AndroidAlarmManager.oneShotAt(
          preAlarmTime, preAlarmId, AlarmReceiver.showUpcomingNotification,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          alarmClock: true,
          allowWhileIdle: true);

      await AndroidAlarmManager.oneShotAt(
          alarm.time, alarm.id, AlarmReceiver.showNotification,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          alarmClock: true,
          allowWhileIdle: true);
    } else {
      // recurring
      await AndroidAlarmManager.periodic(const Duration(hours: 24), preAlarmId,
          AlarmReceiver.showUpcomingNotification,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          startAt: preAlarmTime,
          allowWhileIdle: true);

      await AndroidAlarmManager.periodic(
          const Duration(hours: 24), alarmId, AlarmReceiver.showNotification,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          startAt: alarmTime,
          allowWhileIdle: true);
    }
  }

  static Future<void> rescheduleAlarmOnSnooze(int id) async {
    SqfliteService dbHelper = SqfliteService();
    AlarmItemView? alarmItem = await dbHelper.getAlarm(id);

    if (alarmItem == null) {
      return;
    }

    print('Snoozed Alarm triggered!');
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      (id * 1234).toString(),
      'Snoozed Alarm',
      importance: Importance.high,
      priority: Priority.defaultPriority,
      showWhen: true,
      ongoing: true, // to play sound when the notification shows
      styleInformation: DefaultStyleInformation(true, true),
      autoCancel:
          false, // Prevents the notification from being dismissed when user taps on it.
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('dismiss', 'Dismiss', icon: null)
      ],
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    DateTime alarmTime = DateTime.now().add(Duration(minutes: 10));
    String body = alarmItem.label.isEmpty
        ? formatDateTime(alarmTime)
        : '${formatDateTime(alarmTime)} - ${alarmItem.label}';

    // create the payload
    Map<String, dynamic> payloadData = {
      'id': alarmItem.id,
      'open_alarm_onclick': true,
    };

    await localNotificationsPlugin.show(
        id, 'Snoozed alarm', body, platformChannelSpecifics,
        payload: jsonEncode(payloadData));

    // Update alarm notification (time)
    await AndroidAlarmManager.oneShotAt(
        alarmTime, alarmItem.id, AlarmReceiver.showNotification,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        alarmClock: true,
        allowWhileIdle: true);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('EEE h:mm a').format(dateTime);
  }
}

class AlarmForegroundTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  int _eventCount = 0;
  int _alarmItemId = 0;

  // Called when the task is started.
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    FlutterForegroundTask.wakeUpScreen();
    FlutterForegroundTask.setOnLockScreenVisibility(true);
    //

    _sendPort = sendPort;
    _alarmItemId =
        await FlutterForegroundTask.getData<int>(key: 'alarmItemId') as int;

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

    audioPlayer.setLoopMode(LoopMode.all);
    audioPlayer.play();

    Timer(Duration(minutes: 20), () async {
      // Stop playback after 20 minutes
      await audioPlayer.stop();
    });
  }

  // Called every [interval] milliseconds in [ForegroundTaskOptions].
  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    // FlutterForegroundTask.updateService(
    //   notificationTitle: 'Alarm',
    //   notificationText: 'eventCount: $_eventCount',
    // );

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
  Future<void> onNotificationButtonPressed(String actionId) async {
    print('onNotificationButtonPressed >> $actionId');

    // This is called when a notification or its action is tapped.
    if (actionId == 'snooze') {
      await AlarmReceiver.snoozeAlarm(_alarmItemId);
    } else if (actionId == 'dismiss') {
      await AlarmReceiver.stopAlarm(_alarmItemId);
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
