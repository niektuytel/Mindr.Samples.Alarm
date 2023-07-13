import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:alarm/alarm.dart';
import 'package:client/src/alarm_page/alarm_item.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:path/path.dart' as path;
import 'dart:io' as io;
import 'dart:async';

import 'alarm_page/alarm_notifications.dart';

class DBHelper {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) {
      return _db!;
    }
    _db = await initDatabase();
    return _db!;
  }

  initDatabase() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path1 = path.join(documentsDirectory.path, 'alarm.db');
    var db = await openDatabase(path1, version: 1, onCreate: _onCreate);
    return db;
  }

  Future _onCreate(Database db, int version) async {
    await db.execute("CREATE TABLE alarm("
        "id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "time TEXT, "
        "scheduledDays TEXT, "
        "isEnabled INTEGER, "
        "sound TEXT, "
        "vibrationChecked INTEGER, "
        "syncWithMindr INTEGER)");
  }

  Future<List<AlarmItem>> getAlarms() async {
    var dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.query('alarm');
    List<AlarmItem> alarms = [];
    if (maps.length > 0) {
      for (int i = 0; i < maps.length; i++) {
        alarms.add(AlarmItem.fromMap(maps[i]));
      }
    }
    return alarms;
  }

  Future<AlarmItem?> getAlarm(int id) async {
    var dbClient = await db;
    List<Map<String, dynamic>> result =
        await dbClient.query("alarm", where: "id = ?", whereArgs: [id]);

    if (result.length > 0) {
      return AlarmItem.fromMap(result.first);
    }

    return null;
  }

  Future<int> insert(AlarmItem alarm) async {
    var dbClient = await db;
    int? id = Sqflite.firstIntValue(
        await dbClient.rawQuery('SELECT MAX(id)+1 as id FROM alarm'));
    alarm.id = id ?? 1;
    int res = await dbClient.insert("alarm", alarm.toMap());

    if (alarm.isActive) {
      // upcoming alarm notification
      DateTime preAlarmTime = alarm.time.subtract(Duration(hours: 2));
      await AndroidAlarmManager.oneShotAt(preAlarmTime, (alarm.id * 1234),
          AlarmReceiver.showUpcomingNotification,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          allowWhileIdle: true);

      // alarm notification
      final DateTime now = DateTime.now();
      final DateTime scheduleAlarmDateTime =
          DateTime.now().add(Duration(seconds: 5));

      await AndroidAlarmManager.oneShotAt(
        preAlarmTime,
        (alarm.id * 1334),
        callback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        allowWhileIdle: true,
      );

      // await AndroidAlarmManager.oneShotAt(scheduleAlarmDateTime, 0, callback);
      // // 25 min of vibration
      // final Int64List longVibrationPattern = Int64List(376);
      // if (alarm.vibrationChecked) {
      //   for (var i = 0; i < 376; i += 2) {
      //     longVibrationPattern[i] = 4000; // vibrate
      //     longVibrationPattern[i + 1] = 4000; // pause
      //   }
      // }
      // var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      //   alarm.id.toString(),
      //   'Alarm',
      //   priority: Priority.high,
      //   importance: Importance.high,
      //   sound: RawResourceAndroidNotificationSound('argon'),
      //   audioAttributesUsage: AudioAttributesUsage.alarm,
      //   enableVibration: alarm.vibrationChecked,
      //   vibrationPattern: longVibrationPattern,
      //   // ongoing: true,
      //   visibility: NotificationVisibility.public,
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

      // final String? timeZoneName = await FlutterTimezone.getLocalTimezone();
      // tz.setLocalLocation(tz.getLocation(timeZoneName!));

      // String body = alarm.label.isEmpty
      //     ? AlarmReceiver.formatDateTime(alarm.time)
      //     : '${AlarmReceiver.formatDateTime(alarm.time)} - ${alarm.label}';

      // // create the payload
      // Map<String, dynamic> payloadData = {
      //   'alarmId': alarm.id,
      //   'type': 'showNotification',
      // };

      // await flutterLocalNotificationsPlugin.zonedSchedule(
      //     alarm.id,
      //     'Alarm',
      //     body,
      //     tz.TZDateTime.now(tz.local).add(const Duration(seconds: 20)),
      //     platformChannelSpecifics,
      //     androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      //     uiLocalNotificationDateInterpretation:
      //         UILocalNotificationDateInterpretation.absoluteTime,
      //     payload: jsonEncode(payloadData));

      // // Foreground task
      // WidgetsBinding.instance.addPostFrameCallback((_) async {
      //   // // TODO: maybe later use this on specific versions of android
      //   // await _requestPermissionForAndroid();

      //   _initForegroundTask();

      //   // You can get the previous ReceivePort without restarting the service.
      //   if (await FlutterForegroundTask.isRunningService) {
      //     final newReceivePort = FlutterForegroundTask.receivePort;
      //     _registerReceivePort(newReceivePort, context);
      //   }
      // });

      // // // Navigator.pop(context);

      // // You can save data using the saveData function.
      // await FlutterForegroundTask.saveData(key: 'customData', value: 'hello');

      // // Register the receivePort before starting the service.
      // final ReceivePort? receivePort = FlutterForegroundTask.receivePort;
      // final bool isRegistered = _registerReceivePort(receivePort, context);
      // if (!isRegistered) {
      //   print('Failed to register receivePort!');
      //   return -1;
      // }

      // DateTime alarmTime =
      //     DateTime.now().add(const Duration(seconds: 5)); //  alarm.time;
      // await AndroidAlarmManager.oneShotAt(
      //     alarmTime, alarm.id, AlarmReceiver.showNotification,
      //     exact: true,
      //     wakeup: true,
      //     rescheduleOnReboot: true,
      //     alarmClock: true,
      //     allowWhileIdle: true);
      // // Alarm.set(alarmSettings: buildAlarmSettings(alarm.id)).then((res) {
      // //   print("Then called after settings alarm");
      // //   // if (res) Navigator.pop(context, true);
      // // });
    }

    return res;
  }

  void _initForegroundTask() {
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
  }

  AlarmSettings buildAlarmSettings(int id) {
    final now = DateTime.now();
    // final id = creating
    //     ? DateTime.now().millisecondsSinceEpoch % 100000
    //     : widget.alarmSettings!.id;

    // DateTime dateTime = DateTime(
    //   now.year,
    //   now.month,
    //   now.day,
    //   selectedTime.hour,
    //   selectedTime.minute,
    //   0,
    //   0,
    // );

    DateTime dateTime =
        DateTime.now().add(const Duration(seconds: 5)); //  alarm.time;
    // if (dateTime.isBefore(DateTime.now())) {
    //   dateTime = dateTime.add(const Duration(days: 1));
    // }

    final alarmSettings = AlarmSettings(
        id: id,
        dateTime: dateTime,
        loopAudio: true,
        vibrate: true,
        notificationTitle: true ? 'Alarm example' : null,
        notificationBody: true ? 'Your alarm ($id) is ringing' : null,
        assetAudioPath: 'assets/marimba.mp3',
        stopOnNotificationOpen: false,
        enableNotificationOnKill: false);
    return alarmSettings;
  }

  Future<int> update(AlarmItem alarm) async {
    var dbClient = await db;
    int res = await dbClient
        .update("alarm", alarm.toMap(), where: "id = ?", whereArgs: [alarm.id]);

    if (alarm.isActive) {
      await AndroidAlarmManager.oneShotAt(
          alarm.time, alarm.id, AlarmReceiver.showNotification);
    } else {
      await AndroidAlarmManager.cancel(alarm.id);
    }

    return res;
  }

  Future<int> delete(int id) async {
    var dbClient = await db;
    int res = await dbClient.rawDelete('DELETE FROM alarm WHERE id = ?', [id]);
    return res;
  }

////////////////////////////////////////////
  ///

  ///
  ///
  // ReceivePort? _receivePort;
  // bool _registerReceivePort(ReceivePort? newReceivePort, BuildContext context) {
  //   if (newReceivePort == null) {
  //     return false;
  //   }

  //   _closeReceivePort();

  //   _receivePort = newReceivePort;
  //   _receivePort?.listen((data) {
  //     if (data is int) {
  //       print('eventCount: $data');
  //     } else if (data is String) {
  //       if (data == 'onNotificationPressed') {
  //         Navigator.of(context).pushNamed('/resume-route');
  //       }
  //     } else if (data is DateTime) {
  //       print('timestamp: ${data.toString()}');
  //     }
  //   });

  //   return _receivePort != null;
  // }

  static void callback() {
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

    FlutterForegroundTask.startService(
      notificationTitle: 'Foreground Service is running',
      notificationText: 'Tap to return to the app',
      callback: startCallback,
    );
  }
  // void _closeReceivePort() {
  //   _receivePort?.close();
  //   _receivePort = null;
  // }
}
