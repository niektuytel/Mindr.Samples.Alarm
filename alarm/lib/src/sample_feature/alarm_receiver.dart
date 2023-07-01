import 'dart:convert';
import 'dart:typed_data';

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
    pendingPayload = response.payload;

    // This is needed to show the AlarmScreen when the app is in the foreground
    runApp(
      MaterialApp(
        home: AlarmScreen(payload: response.payload),
      ),
    );
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

// static Future<void> showFullScreenNotification(
//       Alarm alarm, tz.TZDateTime date) async {

//     const int insistentFlag = 4;

//     final Int64List vibrationPattern = Int64List(4);
//     vibrationPattern[0] = 0;
//     vibrationPattern[1] = 4000;
//     vibrationPattern[2] = 4000;
//     vibrationPattern[3] = 4000;

//     AndroidNotificationDetails androidPlatformChannelSpecifics =
//     AndroidNotificationDetails(
//       alarm.id.toString(),
//       'scheduled_alarm_channel',
//       channelDescription: 'scheduled_alarm',
//       priority: Priority.high,
//       importance: Importance.high,
//       additionalFlags: Int32List.fromList(<int>[insistentFlag]),
//       playSound: true,
//       audioAttributesUsage: AudioAttributesUsage.alarm,
//       vibrationPattern: vibrationPattern,
//     );

//     NotificationDetails details =
//     NotificationDetails(android: androidPlatformChannelSpecifics);

//     await flutterLocalNotificationsPlugin..zonedSchedule(
//       ...
//       date,
//       androidAllowWhileIdle: true,
//       ...
//     );
//   }

  static Future<void> showNotification(int id) async {
    DBHelper dbHelper = DBHelper();
    AlarmItem? alarmItem = await dbHelper.getAlarm(id);

    if (alarmItem == null) {
      return;
    }

    print('Alarm triggered!');

    // cancel the upcoming alarm notification
    await flutterLocalNotificationsPlugin.cancel(alarmItem.id * 1234);

    const int insistentFlag = 4;

    final Int64List vibrationPattern = Int64List(4);
    vibrationPattern[0] = 0;
    vibrationPattern[1] = 4000;
    vibrationPattern[2] = 4000;
    vibrationPattern[3] = 4000;

    var androidPlatformChannelSpecifics =
        AndroidNotificationDetails(alarmItem.id.toString(), 'Alarm',
            // importance: Importance.high,
            // priority: Priority.max,
            // showWhen: true,
            // ongoing: true, // Makes the notification persistent.
            // playSound: true, // to play sound when the notification shows
            // sound: RawResourceAndroidNotificationSound('soft_alarm.mp3'),
            styleInformation: DefaultStyleInformation(true, true),
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction('snooze', 'Snooze', icon: null),
              AndroidNotificationAction('dismiss', 'Dismiss', icon: null)
            ],
            priority: Priority.high,
            importance: Importance.high,
            additionalFlags: Int32List.fromList(<int>[insistentFlag]),
            playSound: true,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            vibrationPattern: vibrationPattern);

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

    // // This is needed to show the AlarmScreen when the app is in the foreground
    // pendingPayload = jsonEncode(payloadData);
    // runApp(
    //   MaterialApp(
    //     home: AlarmScreen(payload: jsonEncode(payloadData)),
    //   ),
    // );
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
