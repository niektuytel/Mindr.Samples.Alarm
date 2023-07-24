import 'dart:convert';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:mindr.alarm/src/services/shared_preferences_service.dart';
import 'package:mindr.alarm/src/services/sqflite_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/src/platform_specifics/android/enums.dart'
    as visualizer;

import '../../main.dart';
import '../alarm_page/alarm_screen.dart';
import '../models/alarm_item_view.dart';
import '../utils/datatimeUtils.dart';
import 'alarm_foreground_triggered_task_handler.dart';
import 'alarm_service.dart';

// This must be a top-level function, outside of any class.
@pragma('vm:entry-point')
Future<void> notificationHandler(NotificationResponse response) async {
  print(
      'Notification handler id:${response.id} payload:${response.payload!} action:${response.actionId}');

  int alarmItemId = jsonDecode(response.payload!)['id'];
  bool? openAlarmOnClick = jsonDecode(response.payload!)['open_alarm_onclick'];

  // This is called when a notification or its action is tapped.
  if (response.actionId != null) {
    if (response.actionId == 'snooze') {
      await AlarmHandler.snoozeAlarm(alarmItemId);
    } else if (response.actionId == 'dismiss') {
      await AlarmService.stopAlarm(alarmItemId);
    }

    return;
  }

  await SharedPreferencesService.setActiveAlarmItemId(alarmItemId);
  if (openAlarmOnClick == true) {
    // Open the alarm screen, when app is in background.
    if (navigatorKey.currentState != null) {
      await navigatorKey.currentState!
          .pushNamed('${AlarmScreen.routeName}/$alarmItemId');
    }
  }
}

class AlarmHandler {
  @pragma('vm:entry-point')
  static Future<void> showUpcomingNotification(int id) async {
    int itemId = (id / 1234).truncate();

    SqfliteService dbHelper = SqfliteService();
    AlarmItemView? alarmItem = await dbHelper.getAlarm(itemId);

    if (alarmItem == null || alarmItem.enabled == false) {
      return;
    }

    final FlutterLocalNotificationsPlugin localNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: notificationHandler,
      onDidReceiveBackgroundNotificationResponse: notificationHandler,
    );

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
        ? DateTimeUtils.formatDateTime(alarmItem.time)
        : '${DateTimeUtils.formatDateTime(alarmItem.time)} - ${alarmItem.label}';

    // create the payload
    Map<String, dynamic> payloadData = {
      'id': alarmItem.id,
      'open_alarm_onclick': true,
    };

    await localNotificationsPlugin.show(
        id, 'Upcoming alarm', body, platformChannelSpecifics,
        payload: jsonEncode(payloadData));
  }

  @pragma('vm:entry-point')
  static Future<bool> showNotification(int id) async {
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

  @pragma('vm:entry-point')
  static Future<AlarmItemView?> stopAlarm(int id) async {
    print('Stop alarm');

    SqfliteService dbHelper = SqfliteService();
    AlarmItemView? alarmItem = await dbHelper.getAlarm(id);

    if (alarmItem == null) {
      print('AlarmItem is null');
      return null;
    }

    // cancel the upcoming alarm notification and the alarm
    await SharedPreferencesService.removeActiveAlarmId();
    // await localNotificationsPlugin.cancel(alarmItem.id * 1234); // upcoming
    // await localNotificationsPlugin.cancel(alarmItem.id);
    await AndroidAlarmManager.cancel(alarmItem.id * 1234);
    await AndroidAlarmManager.cancel(alarmItem.id);
    await FlutterForegroundTask.stopService();
    return alarmItem;
  }

  static Future<void> snoozeAlarm(int id) async {
    SqfliteService dbHelper = SqfliteService();
    AlarmItemView? alarmItem = await dbHelper.getAlarm(id);

    if (alarmItem == null) {
      return;
    }

    print('Snoozing alarm for 10 minutes...');

    // cancel the upcoming alarm notification and the alarm
    // await localNotificationsPlugin.cancel(alarmItem.id * 1234);
    // await localNotificationsPlugin.cancel(alarmItem.id);
    await FlutterForegroundTask.stopService();

    // show snoozed alarm
    await rescheduleAlarmOnSnooze(alarmItem.id);
  }

  @pragma('vm:entry-point')
  static Future<bool> scheduleAlarm(AlarmItemView alarm) async {
    debugPrint('Setting alarm with id: ${alarm.id}');

    if (!alarm.enabled) {
      debugPrint('Alarm is not enabled. Cancelling...');
      await AlarmService.stopAlarm(alarm.id);
      return false;
    }

    bool isSuccess = true;
    List<AlarmInfo> alarms = [
      AlarmInfo(
          id: alarm.id * 1234,
          time: alarm.time.subtract(Duration(hours: 2)),
          callback: AlarmHandler.showUpcomingNotification),
      AlarmInfo(
          id: alarm.id,
          time: alarm.time,
          callback: AlarmHandler.showNotification)
    ];

    // // restart the upcoming alarm notification (can been show what have not to be hidden)
    // await localNotificationsPlugin.cancel(alarm.id * 1234);

    for (var info in alarms) {
      debugPrint(
          'Scheduling ${info.callback == AlarmHandler.showNotification ? 'main' : 'pre'} alarm...');

      isSuccess = await AndroidAlarmManager.oneShotAt(
          info.time, info.id, info.callback,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          alarmClock: true,
          allowWhileIdle: true);

      debugPrint(isSuccess ? 'Alarm set successfully' : 'Failed to set alarm');

      if (!isSuccess) break;
    }

    return isSuccess;
  }

  @pragma('vm:entry-point')
  static Future<void> rescheduleAlarmOnSnooze(int id) async {
    SqfliteService dbHelper = SqfliteService();
    AlarmItemView? alarmItem = await dbHelper.getAlarm(id);

    if (alarmItem == null) {
      return;
    }

    final FlutterLocalNotificationsPlugin localNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: notificationHandler,
      onDidReceiveBackgroundNotificationResponse: notificationHandler,
    );

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
        ? DateTimeUtils.formatDateTime(alarmTime)
        : '${DateTimeUtils.formatDateTime(alarmTime)} - ${alarmItem.label}';

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
        alarmTime, alarmItem.id, AlarmHandler.showNotification,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        alarmClock: true,
        allowWhileIdle: true);
  }
}

class AlarmInfo {
  int id;
  DateTime time;
  Function callback;

  AlarmInfo({required this.id, required this.time, required this.callback});
}
