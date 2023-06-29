import 'dart:convert';

import 'package:alarm/src/sample_feature/sample_item.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'alarm_screen.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';

String? pendingPayload; // Declare a global variable to hold the pending payload

// This must be a top-level function, outside of any class.
@pragma('vm:entry-point')
void backgroundNotificationHandler(NotificationResponse response) async {
  if (response.payload != null) {
    Map<String, dynamic> data = jsonDecode(response.payload!);
    if (data['isSnooze'] as bool) {
      AlarmReceiver.snoozeNotification(data['id'] as int);
    } else {
      AndroidAlarmManager.cancel(data['id'] as int);
    }
  }
}

class AlarmReceiver {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static void init(BuildContext context) async {
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // This is called when a notification is tapped.
        // Store the payload instead of navigating immediately
        pendingPayload = response.payload;
      },
      onDidReceiveBackgroundNotificationResponse: backgroundNotificationHandler,
    );
  }

  static Future<void> showUpcomingNotification(int id) async {
    DBHelper dbHelper = DBHelper();
    AlarmItem? alarmItem = await dbHelper.getAlarm(id);

    if (alarmItem == null) {
      return;
    }

    print('Upcoming Alarm triggered!');
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      alarmItem.id.toString(),
      alarmItem.id.toString(),
      importance: Importance.high,
      priority: Priority.defaultPriority,
      showWhen: true,
      styleInformation: DefaultStyleInformation(true, true),
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(alarmItem.id.toString(), 'Dismiss alarm',
            titleColor: const Color.fromRGBO(28, 56, 134, 1),
            icon: null,
            cancelNotification: true)
      ],
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    String body = alarmItem.label.isEmpty
        ? formatDateTime(alarmItem.time)
        : '${formatDateTime(alarmItem.time)} - ${alarmItem.label}';

    await flutterLocalNotificationsPlugin.show(
        id, 'Upcoming alarm', body, platformChannelSpecifics);
  }

  static Future<void> showNotification(int id) async {
    DBHelper dbHelper = DBHelper();
    AlarmItem? alarmItem = await dbHelper.getAlarm(id);

    if (alarmItem == null) {
      return;
    }

    print('Alarm triggered!');
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      alarmItem.id.toString(),
      alarmItem.id.toString(),
      importance: Importance.high,
      priority: Priority.max,
      showWhen: true,
      fullScreenIntent: true,
      playSound: true, // to play sound when the notification shows
      // sound: RawResourceAndroidNotificationSound('alarm_sound'), // the sound file
      styleInformation: DefaultStyleInformation(true, true),
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('snooze', 'Snooze', icon: null),
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
      'id': id,
      'isSnooze': true,
    };

    await flutterLocalNotificationsPlugin.show(
        id, 'Alarm', body, platformChannelSpecifics,
        payload: jsonEncode(payloadData));
  }

  static Future<void> showSnoozedNotification(int id) async {
    DBHelper dbHelper = DBHelper();
    AlarmItem? alarmItem = await dbHelper.getAlarm(id);

    if (alarmItem == null) {
      return;
    }

    print('Snoozed Alarm triggered!');
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      alarmItem.id.toString(),
      alarmItem.id.toString(),
      importance: Importance.high,
      priority: Priority.defaultPriority,
      showWhen: true,
      styleInformation: DefaultStyleInformation(true, true),
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(alarmItem.id.toString(), 'Dismiss alarm',
            titleColor: const Color.fromRGBO(28, 56, 134, 1),
            icon: null,
            cancelNotification: true)
      ],
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    String body = alarmItem.label.isEmpty
        ? formatDateTime(alarmItem.time)
        : '${formatDateTime(alarmItem.time)} - ${alarmItem.label}';

    await flutterLocalNotificationsPlugin.show(
        id, 'Snoozed alarm', body, platformChannelSpecifics);
  }

  static Future<void> showMissedNotification(int id) async {
    DBHelper dbHelper = DBHelper();
    AlarmItem? alarmItem = await dbHelper.getAlarm(id);

    if (alarmItem == null) {
      return;
    }

    print('Missed Alarm triggered!');
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        alarmItem.id.toString(), alarmItem.id.toString(),
        importance: Importance.high,
        priority: Priority.defaultPriority,
        showWhen: true,
        styleInformation: DefaultStyleInformation(true, true));

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    String body = "Alarm was replaced by another alarm.";
    // alarmItem.label.isEmpty
    //     ? formatDateTime(alarmItem.time)
    //     : '${formatDateTime(alarmItem.time)} - ${alarmItem.label}';

    await flutterLocalNotificationsPlugin.show(
        id, 'Missed alarm', body, platformChannelSpecifics);
  }

  // this will be triggered when the user taps on the 'Snooze' action
  static Future<void> snoozeNotification(int id) async {
    DBHelper dbHelper = DBHelper();
    AlarmItem? alarmItem = await dbHelper.getAlarm(id);

    if (alarmItem == null) {
      return;
    }

    DateTime snoozeTime = DateTime.now()
        .add(Duration(minutes: 10)); // modify this duration based on your needs

    // create the payload
    Map<String, dynamic> payloadData = {
      'id': id,
      'isSnooze': false,
    };

    await AndroidAlarmManager.oneShotAt(
        snoozeTime, alarmItem.id, AlarmReceiver.showSnoozedNotification,
        exact: true,
        wakeup: true,
        params: payloadData); // send payload to the snoozed notification
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('EEE h:mm a').format(dateTime);
  }
}
