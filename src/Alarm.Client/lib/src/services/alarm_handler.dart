import 'dart:convert';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:mindr.alarm/src/services/shared_preferences_service.dart';
import 'package:mindr.alarm/src/services/sqflite_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

import '../models/alarm_item_view.dart';
import 'alarm_service.dart';

class AlarmHandler {
  @pragma('vm:entry-point')
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

  @pragma('vm:entry-point')
  static Future<void> showUpcomingNotification(int id) async {
    int itemId = (id / 1234).truncate();

    SqfliteService dbHelper = SqfliteService();
    AlarmItemView? alarmItem = await dbHelper.getAlarm(itemId);

    if (alarmItem == null || alarmItem.enabled == false) {
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

  @pragma('vm:entry-point')
  static Future<bool> showNotification(int id) async {
    print('Alarm triggered! id: $id');
    SqfliteService dbHelper = SqfliteService();
    AlarmItemView? alarmItem = await dbHelper.getAlarm(id);

    if (alarmItem == null || alarmItem.enabled == false) {
      return false;
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
    await localNotificationsPlugin.cancel(alarmItem.id * 1234); // upcoming
    await localNotificationsPlugin.cancel(alarmItem.id);
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
    await localNotificationsPlugin.cancel(alarmItem.id * 1234);
    await localNotificationsPlugin.cancel(alarmItem.id);
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

    // restart the upcoming alarm notification (can been show what have not to be hidden)
    await localNotificationsPlugin.cancel(alarm.id * 1234);

    for (var info in alarms) {
      debugPrint(
          'Scheduling ${info.callback == AlarmHandler.showNotification ? 'main' : 'pre'} alarm...');

      // Check if current day is in the scheduledDays list
      if (alarm.scheduledDays.isNotEmpty) {
        int currentDay = DateTime.now().weekday;
        if (!alarm.scheduledDays.contains(currentDay)) {
          print('Today is not a scheduled day for this alarm, set next day');

          var dayOfWeek = DateTime.now().weekday;
          var nextDay = alarm.scheduledDays.firstWhere(
              (element) => element > dayOfWeek,
              orElse: () => alarm.scheduledDays.first);

          // calculate the number of days to add
          int daysToAdd = nextDay > dayOfWeek
              ? nextDay - dayOfWeek
              : 7 - dayOfWeek + nextDay;

          info.time = info.time.add(Duration(days: daysToAdd));
        }
      }

      isSuccess = alarm.scheduledDays.isEmpty
          ? await AndroidAlarmManager.oneShotAt(
              info.time, info.id, info.callback,
              exact: true,
              wakeup: true,
              rescheduleOnReboot: true,
              alarmClock: true,
              allowWhileIdle: true)
          : await AndroidAlarmManager.periodic(
              Duration(hours: 24), info.id, info.callback,
              exact: true,
              wakeup: true,
              rescheduleOnReboot: true,
              startAt: info.time,
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
        alarmTime, alarmItem.id, AlarmHandler.showNotification,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        alarmClock: true,
        allowWhileIdle: true);
  }

  @pragma('vm:entry-point')
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('EEE h:mm a').format(dateTime);
  }

  @pragma('vm:entry-point')
  static Future<AlarmItemView> setNextItemTime(AlarmItemView item) async {
    var nextTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      item.time.hour,
      item.time.minute,
    );

    if (!item.enabled) {
      return item;
    } else if (item.scheduledDays.isEmpty) {
      if (nextTime.isBefore(DateTime.now())) {
        nextTime = nextTime.add(Duration(days: 1));
      }

      item.time = nextTime;
      print('Next time: ${item.time}');
      return item;
    }

    var dayOfWeek = nextTime.weekday;
    var nextDay = item.scheduledDays.firstWhere(
        (element) => element > dayOfWeek,
        orElse: () => item.scheduledDays.first);

    // calculate the number of days to add
    int daysToAdd =
        (nextDay > dayOfWeek ? nextDay - dayOfWeek : 7 - dayOfWeek + nextDay);

    item.time = nextTime.add(Duration(days: daysToAdd));
    print('Next time: ${item.time}');
    return item;
  }
}

class AlarmInfo {
  int id;
  DateTime time;
  Function callback;

  AlarmInfo({required this.id, required this.time, required this.callback});
}
