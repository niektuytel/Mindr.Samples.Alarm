import 'dart:async';
import 'dart:convert';

import 'package:mindr.alarm/src/models/alarm_item_view.dart';
import 'package:mindr.alarm/src/services/shared_preferences_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../main.dart';
import '../alarm_page/alarm_screen.dart';
import '../utils/datatimeUtils.dart';
import 'alarm_handler.dart';
import 'alarm_foreground_triggered_task_handler.dart';
import 'sqflite_service.dart';

class AlarmService {
  static Future<bool> insertAlarm(AlarmItemView alarm) async {
    print('Insert alarm: ${alarm.toMap().toString()}');

    alarm = await DateTimeUtils.setNextItemTime(alarm);
    await SqfliteService().insertAlarm(alarm);

    // todo: add alarm to api when have internet connection (no authentication needed, will delete items from api when not been used)

    return await AlarmHandler.scheduleAlarm(alarm);
  }

  static Future<bool> updateAlarm(
      AlarmItemView alarm, bool updateAlarmManager) async {
    print('Updating alarm: ${alarm.toMap().toString()}');

    alarm = await DateTimeUtils.setNextItemTime(alarm);
    await SqfliteService().updateAlarm(alarm);

    // todo: add alarm to api when have internet connection (no authentication needed, will delete items from api when not been used)

    if (updateAlarmManager) {
      return await AlarmHandler.scheduleAlarm(alarm);
    }

    return true;
  }

  static Future<void> stopAlarm(int id) async {
    try {
      print('Stop alarm: $id');
      var alarmItem = await AlarmHandler.stopAlarm(id);

      // Set next alarm if alarm is recurring
      await handleNextAlarmIfExist(alarmItem);

      // todo: add alarm to api when have internet connection (no authentication needed, will delete items from api when not been used)
    } catch (error) {
      print('An error occurred in stopAlarm: $error');
    }
  }

  static Future<void> handleNextAlarmIfExist(AlarmItemView? item) async {
    if (item == null || !item.enabled || item.scheduledDays.isEmpty) {
      return;
    }

    var updateStatus = await updateAlarm(item, true);

    if (!updateStatus) {
      print('Failed to update the alarm');
    }
  }

  static Future<void> deleteAlarm(int id) async {
    print('Delete alarm: ${id}');
    // todo: add alarm to api when have internet connection (no authentication needed, will delete items from api when not been used)

    await AlarmHandler.stopAlarm(id);
    await SqfliteService().deleteAlarm(id);
  }
}
