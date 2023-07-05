import 'dart:convert';
import 'dart:typed_data';

import 'package:alarm/src/alarm_page/alarm_item.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alarm_intent_screen.dart';
import 'package:intl/intl.dart';
import '../db_helper.dart';

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

  // Future<void> _showFullScreenNotification() async {
  //   await showDialog(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       title: const Text('Turn off your screen'),
  //       content: const Text(
  //           'to see the full-screen intent in 5 seconds, press OK and TURN '
  //           'OFF your screen'),
  //       actions: <Widget>[
  //         TextButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //           },
  //           child: const Text('Cancel'),
  //         ),
  //         TextButton(
  //           onPressed: () async {
  //             await flutterLocalNotificationsPlugin.zonedSchedule(
  //                 0,
  //                 'scheduled title',
  //                 'scheduled body',
  //                 tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
  //                 const NotificationDetails(
  //                     android: AndroidNotificationDetails(
  //                         'full screen channel id', 'full screen channel name',
  //                         channelDescription: 'full screen channel description',
  //                         priority: Priority.high,
  //                         importance: Importance.high,
  //                         fullScreenIntent: true)),
  //                 androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  //                 uiLocalNotificationDateInterpretation:
  //                     UILocalNotificationDateInterpretation.absoluteTime);

  //             Navigator.pop(context);
  //           },
  //           child: const Text('OK'),
  //         )
  //       ],
  //     ),
  //   );
  // }

  static Future<void> showNotification(int id) async {
    DBHelper dbHelper = DBHelper();
    AlarmItem? alarmItem = await dbHelper.getAlarm(id);

    if (alarmItem == null) {
      return;
    }

    print('Alarm triggered!');

    // cancel the upcoming alarm notification
    await flutterLocalNotificationsPlugin.cancel(alarmItem.id * 1234);

    // 25 min of vibration
    final Int64List longVibrationPattern = Int64List(376);
    if (alarmItem.vibrationChecked) {
      for (var i = 0; i < 376; i += 2) {
        longVibrationPattern[i] = 4000; // vibrate
        longVibrationPattern[i + 1] = 4000; // pause
      }
    }

    // Setup your custom sound here.
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      alarmItem.id.toString(),
      'Alarm',
      priority: Priority.high,
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('argon'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      vibrationPattern: longVibrationPattern,
      styleInformation: DefaultStyleInformation(true, true),
      fullScreenIntent: true,
      autoCancel:
          false, // Prevents the notification from being dismissed when user taps on it.
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
      'alarmId': alarmItem.id,
      'type': 'showNotification',
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
