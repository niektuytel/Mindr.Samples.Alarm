import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:alarm/alarm.dart';
import 'package:client/src/models/alarm_item_view.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:client/src/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../models/alarm_brief_item.dart';
import '../widgets/alarm_screen.dart';
import 'package:intl/intl.dart';
import '../services/sqflite_service.dart';
import 'alarm_page.dart';
import 'services/foreground_task_handler.dart';

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
    navigatorKey.currentState!
        .push(MaterialPageRoute(builder: (_) => AlarmScreen(alarmItemId)));
  }
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

    await localNotificationsPlugin.show(
        id, 'Upcoming alarm', body, platformChannelSpecifics,
        payload: jsonEncode(payloadData));
  }

  static Future<bool> showNotification(int id) async {
    print('Alarm triggered!');
    SqfliteService dbHelper = SqfliteService();
    AlarmItemView? alarmItem = await dbHelper.getAlarm(id);

    if (alarmItem == null) {
      return false;
    }

    // cancel the upcoming alarm notification
    await localNotificationsPlugin.cancel(alarmItem.id * 1234);

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        id: 500,
        channelId: 'notification_channel_id',
        channelName: 'Foreground Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
          backgroundColor: Colors.orange,
        ),
        buttons: [
          const NotificationButton(
            id: 'sendButton',
            text: 'Send',
            textColor: Colors.orange,
          ),
          const NotificationButton(
            id: 'testButton',
            text: 'Test',
            textColor: Colors.grey,
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

    // You can save data using the saveData function.
    await FlutterForegroundTask.saveData(
        key: 'alarmItemId', value: alarmItem.id);

    return FlutterForegroundTask.startService(
      notificationTitle: 'Foreground Service is running',
      notificationText: 'Tap to return to the app',
      callback: startCallback,
    );

    // if (await FlutterForegroundTask.isRunningService) {
    //   return FlutterForegroundTask.restartService();
    // } else {
    //   return FlutterForegroundTask.startService(
    //     notificationTitle: 'Foreground Service is running',
    //     notificationText: 'Tap to return to the app',
    //     callback: startCallback,
    //   );
    // }
  }

  static Future<void> stopAlarm(int id) async {
    SqfliteService dbHelper = SqfliteService();
    AlarmItemView? alarmItem = await dbHelper.getAlarm(id);

    if (alarmItem == null) {
      return;
    }

    print('Stop alarm');

    // cancel the upcoming alarm notification and the alarm
    await localNotificationsPlugin.cancel(alarmItem.id * 1234); // upcoming
    await localNotificationsPlugin.cancel(alarmItem.id);
    FlutterForegroundTask.stopService();
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
    scheduleSnoozedNotification(alarmItem.id);
  }

  static Future<void> scheduleSnoozedNotification(int id) async {
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

////////////////////////// FOREGROUND SERVICES //////////////////////////

// The callback function should always be a top-level function.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(AlarmForegroundTaskHandler());
  // // The setTaskHandler function must be called to handle the task in the background.
  // FlutterForegroundTask.setTaskHandler(AlarmTaskHandler());
}
