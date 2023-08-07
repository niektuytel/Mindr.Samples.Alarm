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
  @pragma('vm:entry-point')
  static Future<void> setAlarm(AlarmEntity alarm) async {
    if (Platform.isAndroid) {
      try {
        debugPrint('setAlarm: ${jsonEncode(alarm.toMap())}');
        const platform = MethodChannel('com.mindr.alarm/alarm_trigger');
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

  @pragma('vm:entry-point')
  static Future<void> removeAlarm(int alarmId) async {
    if (Platform.isAndroid) {
      try {
        debugPrint('remove alarm: $alarmId');
        const platform = MethodChannel('com.mindr.alarm/alarm_trigger');
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

  @pragma('vm:entry-point')
  static Future<bool> scheduleAlarm(AlarmEntity alarm) async {
    if (!alarm.enabled) {
      debugPrint('Alarm is not enabled (id: ${alarm.id}). Cancelling...');
      await removeAlarm(alarm.id);
      return false;
    }

    await setAlarm(alarm);
    return true;
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
}
