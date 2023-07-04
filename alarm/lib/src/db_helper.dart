import 'dart:typed_data';

import 'package:alarm/src/alarm_page/alarm_item.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
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
      // // upcoming alarm notification
      // DateTime preAlarmTime = alarm.time.subtract(Duration(hours: 2));
      // await AndroidAlarmManager.oneShotAt(
      //     preAlarmTime, alarm.id * 1234, AlarmReceiver.showUpcomingNotification,
      //     exact: true,
      //     wakeup: true,
      //     rescheduleOnReboot: true,
      //     allowWhileIdle: true);

      // alarm notification
      // 25 min of vibration
      final Int64List longVibrationPattern = Int64List(376);
      if (alarm.vibrationChecked) {
        for (var i = 0; i < 376; i += 2) {
          longVibrationPattern[i] = 4000; // vibrate
          longVibrationPattern[i + 1] = 4000; // pause
        }
      }
      var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        alarm.id.toString(),
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

      tz.initializeTimeZones();
      final String? timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName!));

      // DateTime alarmTime = DateTime.now().add(const Duration(seconds: 5)); //  alarm.time;
      await flutterLocalNotificationsPlugin.zonedSchedule(
          0,
          'scheduled title',
          'scheduled body',
          tz.TZDateTime.now(tz.local).add(const Duration(seconds: 20)),
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime);

      // Navigator.pop(context);

      // await AndroidAlarmManager.oneShotAt(
      //     alarmTime, alarm.id, AlarmReceiver.showNotification,
      //     exact: true,
      //     wakeup: true,
      //     rescheduleOnReboot: true,
      //     alarmClock: true,
      //     allowWhileIdle: true);
    }

    return res;
  }

  // Future<void> showNotification(int id) async {
  //   DBHelper dbHelper = DBHelper();
  //   AlarmItem? alarmItem = await dbHelper.getAlarm(id);

  //   if (alarmItem == null) {
  //     return;
  //   }

  //   print('Alarm triggered!');

  //   // cancel the upcoming alarm notification
  //   await flutterLocalNotificationsPlugin.cancel(alarmItem.id * 1234);

  //   // 25 min of vibration
  //   final Int64List longVibrationPattern = Int64List(376);
  //   if (alarmItem.vibrationChecked) {
  //     for (var i = 0; i < 376; i += 2) {
  //       longVibrationPattern[i] = 4000; // vibrate
  //       longVibrationPattern[i + 1] = 4000; // pause
  //     }
  //   }

  //   // Setup your custom sound here.
  //   var androidPlatformChannelSpecifics = AndroidNotificationDetails(
  //     alarmItem.id.toString(),
  //     'Alarm',
  //     priority: Priority.high,
  //     importance: Importance.high,
  //     sound: RawResourceAndroidNotificationSound('argon'),
  //     audioAttributesUsage: AudioAttributesUsage.alarm,
  //     vibrationPattern: longVibrationPattern,
  //     styleInformation: DefaultStyleInformation(true, true),
  //     fullScreenIntent: true,
  //     autoCancel:
  //         false, // Prevents the notification from being dismissed when user taps on it.
  //     actions: <AndroidNotificationAction>[
  //       AndroidNotificationAction('snooze', 'Snooze', icon: null),
  //       AndroidNotificationAction('dismiss', 'Dismiss', icon: null)
  //     ],
  //   );

  //   var platformChannelSpecifics = NotificationDetails(
  //     android: androidPlatformChannelSpecifics,
  //   );

  //   String body = alarmItem.label.isEmpty
  //       ? formatDateTime(alarmItem.time)
  //       : '${formatDateTime(alarmItem.time)} - ${alarmItem.label}';

  //   // create the payload
  //   Map<String, dynamic> payloadData = {
  //     'alarmId': alarmItem.id,
  //     'type': 'showNotification',
  //   };

  //   await flutterLocalNotificationsPlugin.show(
  //       id, 'Alarm', body, platformChannelSpecifics,
  //       payload: jsonEncode(payloadData));
  // }

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
}
