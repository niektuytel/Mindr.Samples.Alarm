import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:alarm/alarm.dart';
import 'package:client/src/alarm_page/alarm_item.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alarm_intent_screen.dart';
import 'package:intl/intl.dart';
import '../db_helper.dart';
import 'alarm_page.dart';
import 'services/alarm_foreground_task_handler.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// This must be a top-level function, outside of any class.
@pragma('vm:entry-point')
void notificationHandler(NotificationResponse response) async {
  print(
      'Notification handler id:${response.id} payload:${response.payload!} action:${response.actionId}');

  int alarmId = jsonDecode(response.payload!)['alarmId'];
  String type = jsonDecode(response.payload!)['type'];
  int id = response.id!;

  // This is called when a notification or its action is tapped.
  if (response.actionId != null) {
    // cancel upcoming notification
    if (alarmId != id) {
      await AndroidAlarmManager.cancel(id);
      print('Notification handler, delete upcoming notification');
    }

    if (response.actionId == 'snooze') {
      await AlarmReceiver.showSnoozedNotification(alarmId);

      print('Notification handler, snooze notification');
    } else if (response.actionId == 'dismiss') {
      await AndroidAlarmManager.cancel(alarmId);

      // TODO: cancel/remove the alarm in the database, when not have days?
      print('Notification handler, delete notification');
    }
  }

  if (type == 'showNotification' || type == 'showSnoozedNotification') {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('pendingPayload', response.payload!);

    // This is needed to show the AlarmScreen when the app is in the foreground
    runApp(
      MaterialApp(
        home: AlarmScreen(payload: response.payload),
      ),
    );
  }
}

class AlarmReceiver {
  static void init(BuildContext context) async {
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: notificationHandler,
      onDidReceiveBackgroundNotificationResponse: notificationHandler,
    );
  }

  static Future<void> showUpcomingNotification(int id) async {
    int itemId = (id / 1234).truncate();

    DBHelper dbHelper = DBHelper();
    AlarmItem? alarmItem = await dbHelper.getAlarm(itemId);

    if (alarmItem == null) {
      return;
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
        AndroidNotificationAction(id.toString(), 'Dismiss alarm',
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
      'alarmId': alarmItem.id,
      'type': 'showUpcomingNotification',
    };

    await flutterLocalNotificationsPlugin.show(
        id, 'Upcoming alarm', body, platformChannelSpecifics,
        payload: jsonEncode(payloadData));
  }

  static Future<bool> showNotification(int id) async {
    print('Alarm triggered!');
    DBHelper dbHelper = DBHelper();
    AlarmItem? alarmItem = await dbHelper.getAlarm(id);

    if (alarmItem == null) {
      return false;
    }

    // FlutterForegroundTask.init(
    //   androidNotificationOptions: AndroidNotificationOptions(
    //     id: 500,
    //     channelId: 'notification_channel_id',
    //     channelName: 'Foreground Notification',
    //     channelDescription:
    //         'This notification appears when the foreground service is running.',
    //     channelImportance: NotificationChannelImportance.LOW,
    //     priority: NotificationPriority.LOW,
    //     iconData: const NotificationIconData(
    //       resType: ResourceType.mipmap,
    //       resPrefix: ResourcePrefix.ic,
    //       name: 'launcher',
    //       backgroundColor: Colors.orange,
    //     ),
    //     buttons: [
    //       const NotificationButton(
    //         id: 'sendButton',
    //         text: 'Send',
    //         textColor: Colors.orange,
    //       ),
    //       const NotificationButton(
    //         id: 'testButton',
    //         text: 'Test',
    //         textColor: Colors.grey,
    //       ),
    //     ],
    //   ),
    //   iosNotificationOptions: const IOSNotificationOptions(
    //     showNotification: true,
    //     playSound: false,
    //   ),
    //   foregroundTaskOptions: const ForegroundTaskOptions(
    //     interval: 5000,
    //     isOnceEvent: false,
    //     autoRunOnBoot: true,
    //     allowWakeLock: true,
    //     allowWifiLock: true,
    //   ),
    // );

    // // Sound
    // final audioPlayer = AudioPlayer();
    // Duration? audioDuration = await audioPlayer.setAsset('assets/marimba.mp3');
    // audioPlayer.setLoopMode(LoopMode.all);
    // audioPlayer.play();

    // // Stop playback after 20 minutes
    // Timer(Duration(minutes: 20), () async {
    //   await audioPlayer.stop();
    //   await AudioPlayer.clearAssetCache();
    // });

    // cancel the upcoming alarm notification
    await flutterLocalNotificationsPlugin.cancel(alarmItem.id * 1234);

    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    } else {
      return FlutterForegroundTask.startService(
        notificationTitle: 'Foreground Service is running',
        notificationText: 'Tap to return to the app',
        callback: startCallback,
      );
    }

    // // Setup your custom sound here.
    // var androidPlatformChannelSpecifics = AndroidNotificationDetails(
    //   alarmItem.id.toString(),
    //   'Alarm',
    //   priority: Priority.high,
    //   importance: Importance.high,
    //   // sound: RawResourceAndroidNotificationSound('argon'),
    //   // audioAttributesUsage: AudioAttributesUsage.alarm,
    //   // vibrationPattern: longVibrationPattern,
    //   styleInformation: DefaultStyleInformation(true, true),
    //   fullScreenIntent: true,
    //   autoCancel:
    //       false, // Prevents the notification from being dismissed when user taps on it.
    //   actions: <AndroidNotificationAction>[
    //     AndroidNotificationAction('snooze', 'Snooze', icon: null),
    //     AndroidNotificationAction('dismiss', 'Dismiss', icon: null)
    //   ],
    // );

    // var platformChannelSpecifics = NotificationDetails(
    //   android: androidPlatformChannelSpecifics,
    // );

    // String body = alarmItem.label.isEmpty
    //     ? formatDateTime(alarmItem.time)
    //     : '${formatDateTime(alarmItem.time)} - ${alarmItem.label}';

    // // create the payload
    // Map<String, dynamic> payloadData = {
    //   'alarmId': alarmItem.id,
    //   'type': 'showNotification',
    // };

    // await flutterLocalNotificationsPlugin.show(
    //     id, 'Alarm', body, platformChannelSpecifics,
    //     payload: jsonEncode(payloadData));

    // // // play sound
  }

  static Future<void> showSnoozedNotification(int id) async {
    DBHelper dbHelper = DBHelper();
    AlarmItem? alarmItem = await dbHelper.getAlarm(id);

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

    String body = alarmItem.label.isEmpty
        ? formatDateTime(alarmItem.time)
        : '${formatDateTime(alarmItem.time)} - ${alarmItem.label}';

    // create the payload
    Map<String, dynamic> payloadData = {
      'alarmId': alarmItem.id,
      'type': 'showSnoozedNotification',
    };

    await flutterLocalNotificationsPlugin.show(
        id, 'Snoozed alarm', body, platformChannelSpecifics,
        payload: jsonEncode(payloadData));

    // Update alarm notification (time)
    DateTime alarmTime = DateTime.now().add(Duration(minutes: 10));
    await AndroidAlarmManager.oneShotAt(
        alarmTime, alarmItem.id, AlarmReceiver.showNotification,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        alarmClock: true,
        allowWhileIdle: true);
  }

  static Future<void> showMissedNotification(int id) async {
    DBHelper dbHelper = DBHelper();
    AlarmItem? alarmItem = await dbHelper.getAlarm(id);

    if (alarmItem == null) {
      return;
    }

    print('Missed Alarm!');

    // cancel the upcoming alarm notification and the alarm
    await flutterLocalNotificationsPlugin.cancel(alarmItem.id * 1234);
    // await flutterLocalNotificationsPlugin.cancel(alarmItem.id);

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      (alarmItem.id).toString(),
      'Missed Alarm',
      importance: Importance.high,
      priority: Priority.defaultPriority,
      showWhen: true,
      styleInformation: DefaultStyleInformation(true, true),
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    String body = alarmItem.label.isEmpty
        ? formatDateTime(alarmItem.time)
        : '${formatDateTime(alarmItem.time)} - ${alarmItem.label}';

    // create the payload
    Map<String, dynamic> payloadData = {
      'alarmId': alarmItem.id,
      'type': 'showMissedNotification',
    };

    await flutterLocalNotificationsPlugin.show(
        alarmItem.id, 'Missed alarm', body, platformChannelSpecifics,
        payload: jsonEncode(payloadData));
  }

  static Future<void> snoozeNotification(int id) async {
    DBHelper dbHelper = DBHelper();
    AlarmItem? alarmItem = await dbHelper.getAlarm(id);

    if (alarmItem == null) {
      return;
    }

    print('Alarm snoozed!');

    // cancel the upcoming alarm notification and the alarm
    await flutterLocalNotificationsPlugin.cancel(alarmItem.id * 1234);
    await flutterLocalNotificationsPlugin.cancel(alarmItem.id);

    // show snoozed alarm
    showSnoozedNotification(alarmItem.id);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('EEE h:mm a').format(dateTime);
  }
}

////////////////////////// FOREGROUND SERVICES //////////////////////////

// The callback function should always be a top-level function.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(AlarmForegroundTaskHandler());
  // // The setTaskHandler function must be called to handle the task in the background.
  // FlutterForegroundTask.setTaskHandler(AlarmTaskHandler());
}
