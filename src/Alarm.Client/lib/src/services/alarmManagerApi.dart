import 'dart:convert';
import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/services.dart';
import 'package:mindr.alarm/src/models/AlarmActionOnPush.dart';
import 'package:mindr.alarm/src/services/sqflite_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../models/alarmEntity.dart';
import '../utils/datetimeUtils.dart';

class AlarmManagerApi {
  static const platform = MethodChannel('com.mindr.alarm/alarm_trigger');
  static Future<void> setAlarm(AlarmEntity alarm) async {
    if (Platform.isAndroid) {
      try {
        print('setAlarm: ${jsonEncode(alarm.toMap())}');
        await platform.invokeMethod('scheduleAlarm', {
          'alarm': jsonEncode(alarm.toMap()),
        });
      } on PlatformException catch (e) {
        debugPrint('Error in scheduleAlarm: $e');
        // handle error
      }
    } else {
      throw new Exception(
          'Not implemented platform ${Platform.operatingSystem}');
    }
  }

  static Future<void> removeAlarm(int alarmId) async {
    if (Platform.isAndroid) {
      try {
        print('remove alarm: ${alarmId}');
        await platform.invokeMethod('removeAlarm', {
          'id': alarmId.toString(),
        });
      } on PlatformException catch (e) {
        debugPrint('Error in scheduleAlarm: $e');
        // handle error
      }
    } else {
      throw new Exception(
          'Not implemented platform ${Platform.operatingSystem}');
    }
  }

  // @pragma('vm:entry-point')
  // static Future stopAlarm(int id) async {
  //   try {
  //     await removeAlarm(id);

  //     SqfliteService dbHelper = SqfliteService();
  //     AlarmEntity? alarm = await dbHelper.getAlarm(id);
  //     if (alarm == null) {
  //       debugPrint('No alarm found with id: $id');
  //       return null;
  //     }

  //     // stop current notification
  //     if (alarm.scheduledDays.isNotEmpty && alarm.enabled) {
  //       debugPrint('Schedule alarm: ${alarm.toMap().toString()}');
  //       alarm = await DateTimeUtils.setNextItemTime(alarm, alarm.time);
  //       await dbHelper.updateAlarm(alarm);
  //       await setAlarm(alarm);
  //     }
  //   } catch (e) {
  //     debugPrint('Error in stopAlarm: $e');
  //   }
  // }

  // @pragma('vm:entry-point')
  // static Future snoozeAlarm(int id) async {
  //   SqfliteService dbHelper = SqfliteService();
  //   AlarmEntity? alarm = await dbHelper.getAlarm(id);

  //   if (alarm == null) {
  //     debugPrint('Alarm is not enabled (id: $id). Cancelling...');
  //     await stopAlarm(id);
  //     return;
  //   }

  //   // cancel the upcoming alarm notification
  //   var upcomingId = AlarmNotificationApi.getUpcomingId(id);
  //   alarm.time = DateTime.now().add(Duration(minutes: 10));
  //   debugPrint('Schedule alarm: ${alarm.toMap().toString()}');

  //   // show upcoming alarm notification
  //   await AlarmNotificationApi.showSnoozingNotification(
  //       upcomingId, alarm.toMap());

  //   // show alarm
  //   var isSuccess = await AndroidAlarmManager.oneShotAt(
  //       alarm.time, alarm.id, AlarmTriggerApi.execute,
  //       exact: true,
  //       wakeup: true,
  //       rescheduleOnReboot: true,
  //       alarmClock: true,
  //       allowWhileIdle: true,
  //       params: alarm.toMap());

  //   debugPrint(isSuccess ? 'Alarm set successfully' : 'Failed to set alarm');

  //   // cancel the alarm
  //   await FlutterForegroundTask.stopService();
  // }

  @pragma('vm:entry-point')
  static Future<bool> scheduleAlarm(AlarmEntity alarm) async {
    if (!alarm.enabled) {
      debugPrint('Alarm is not enabled (id: ${alarm.id}). Cancelling...');
      await removeAlarm(alarm.id);
      return false;
    }

    // // show fulll screen intent
    // await showFullScreenIntent();

    // // show upcoming alarm notification
    // debugPrint('Schedule alarm: ${alarm.toMap().toString()}');
    // var upcomingId = AlarmNotificationApi.getUpcomingId(alarm.id);
    // var upcomingTime = alarm.time.subtract(Duration(hours: 2));
    // var isSuccess = await AndroidAlarmManager.oneShotAt(
    //     upcomingTime, upcomingId, AlarmNotificationApi.showUpcomingNotification,
    //     exact: true,
    //     wakeup: true,
    //     rescheduleOnReboot: true,
    //     alarmClock: true,
    //     allowWhileIdle: true,
    //     params: alarm.toMap());

    // debugPrint(isSuccess
    //     ? 'Upcoming alarm set successfully'
    //     : 'Failed to set upcoming alarm');

    // show alarm
    // var id = alarm.id;
    // alarm.time = DateTime.now().add(const Duration(seconds: 20));
    // alarm.time;
    await setAlarm(alarm);
    // isSuccess = await AndroidAlarmManager.oneShotAt(
    //     time, id, showFullScreenIntent, //AlarmTriggerApi.execute,
    //     exact: true,
    //     wakeup: true,
    //     rescheduleOnReboot: true,
    //     alarmClock: true,
    //     allowWhileIdle: true,
    //     params: alarm.toMap());

    // debugPrint(isSuccess ? 'Alarm set successfully' : 'Failed to set alarm');

    return true;
    //isSuccess;
  }

  @pragma('vm:entry-point')
  static Future<bool> insertAlarmOnPush(AlarmOnPush pushedAlarm) async {
    var alarm = AlarmEntity(pushedAlarm.time);
    alarm.label = pushedAlarm.label;
    alarm.scheduledDays = pushedAlarm.scheduledDays;
    alarm.sound = pushedAlarm.sound;
    alarm.vibrationChecked = pushedAlarm.vibrationChecked;
    alarm.syncWithMindr = true;

    return await insertAlarm(alarm);
  }

  @pragma('vm:entry-point')
  static Future<bool> insertAlarm(AlarmEntity alarm) async {
    alarm = await DateTimeUtils.setNextItemTime(alarm, DateTime.now());
    await SqfliteService().insertAlarm(alarm);

    return await scheduleAlarm(alarm);
  }

  @pragma('vm:entry-point')
  static Future<bool> updateAlarm(
      AlarmEntity alarm, bool updateAlarmManager) async {
    alarm = await DateTimeUtils.setNextItemTime(alarm, DateTime.now());
    await SqfliteService().updateAlarm(alarm);

    if (updateAlarmManager) {
      // await cancelAllAlarmNotifications(alarm.id);
      await removeAlarm(alarm.id);
      return await scheduleAlarm(alarm);
    }

    return true;
  }

  @pragma('vm:entry-point')
  static Future<void> deleteAlarm(int id) async {
    await removeAlarm(id);
    await SqfliteService().deleteAlarm(id);
  }

  // static Future cancelAllAlarmNotifications(int id) async {
  //   var upcomingId = AlarmNotificationApi.getUpcomingId(id);
  //   await AndroidAlarmManager.cancel(upcomingId);
  //   AlarmNotificationApi.cancel(upcomingId);
  // }
}
