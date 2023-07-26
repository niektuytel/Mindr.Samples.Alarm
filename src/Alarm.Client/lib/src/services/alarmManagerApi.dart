import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:mindr.alarm/src/services/shared_preferences_service.dart';
import 'package:mindr.alarm/src/services/sqflite_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../models/alarmEntity.dart';
import '../utils/datatimeUtils.dart';
import 'alarmTriggerApi.dart';
import 'alarmNotificationApi.dart';

class AlarmManagerApi {
  @pragma('vm:entry-point')
  static Future stopAlarm(int id) async {
    try {
      SqfliteService dbHelper = SqfliteService();
      AlarmEntity? alarmItem = await dbHelper.getAlarm(id);

      if (alarmItem == null) {
        debugPrint('No alarm found with id: $id');
        return null;
      }

      debugPrint('Stopping alarm with id: ${alarmItem.id}');
      if (alarmItem.scheduledDays.isEmpty) {
        // stop alarm
        await FlutterForegroundTask.stopService();
      } else {
        // stop alarm and set next alarm
        alarmItem = await DateTimeUtils.setNextItemTime(alarmItem);
        await dbHelper.updateAlarm(alarmItem);
        await scheduleAlarm(alarmItem);
      }
    } catch (e) {
      debugPrint('Error in stopAlarm: $e');
    }
  }

  @pragma('vm:entry-point')
  static Future snoozeAlarm(int id) async {
    SqfliteService dbHelper = SqfliteService();
    AlarmEntity? alarm = await dbHelper.getAlarm(id);

    if (alarm == null) {
      return;
    }

    // cancel the alarm
    await FlutterForegroundTask.stopService();

    // set alarm time to 10 minutes from now
    alarm.time = DateTime.now().add(Duration(minutes: 10));
    var snoozingId = AlarmNotificationApi.getUpcomingId(alarm.id);

    // show alarm notification
    await AlarmNotificationApi.showSnoozingNotification(
        snoozingId, alarm.toMap());

    debugPrint('Scheduling alarm ...');
    var isSuccess = await AndroidAlarmManager.oneShotAt(
        alarm.time, alarm.id, AlarmTriggerApi.execute,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        alarmClock: true,
        allowWhileIdle: true,
        params: alarm.toMap());

    debugPrint(isSuccess ? 'Alarm set successfully' : 'Failed to set alarm');
  }

  @pragma('vm:entry-point')
  static Future<bool> scheduleAlarm(AlarmEntity alarm) async {
    debugPrint('Setting alarm with id: ${alarm.id}');

    // cancel the alarm(if runs, be sure to cancel it)
    await FlutterForegroundTask.stopService();

    if (!alarm.enabled) {
      debugPrint('Alarm is not enabled. Cancelling...');
      await stopAlarm(alarm.id);
      return false;
    }

    // show upcoming alarm notification
    debugPrint('Scheduling upcoming alarm...');
    var upcomingId = AlarmNotificationApi.getUpcomingId(alarm.id);
    var upcomingTime = alarm.time.subtract(Duration(hours: 2));
    var isSuccess = await AndroidAlarmManager.oneShotAt(
        upcomingTime, upcomingId, AlarmNotificationApi.showUpcomingNotification,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        alarmClock: true,
        allowWhileIdle: true,
        params: alarm.toMap());

    debugPrint(isSuccess
        ? 'Upcoming alarm set successfully'
        : 'Failed to set upcoming alarm');

    // show alarm notification
    debugPrint('Scheduling alarm...');
    var id = alarm.id;
    var time = alarm.time;
    isSuccess = await AndroidAlarmManager.oneShotAt(
        time, id, AlarmTriggerApi.execute,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        alarmClock: true,
        allowWhileIdle: true,
        params: alarm.toMap());

    debugPrint(isSuccess ? 'Alarm set successfully' : 'Failed to set alarm');

    return isSuccess;
  }

  @pragma('vm:entry-point')
  static Future<bool> insertAlarm(AlarmEntity alarm) async {
    print('Insert alarm: ${alarm.toMap().toString()}');

    alarm = await DateTimeUtils.setNextItemTime(alarm);
    await SqfliteService().insertAlarm(alarm);

    // todo: add alarm to api when have internet connection (no authentication needed, will delete items from api when not been used)

    return await AlarmManagerApi.scheduleAlarm(alarm);
  }

  @pragma('vm:entry-point')
  static Future<bool> updateAlarm(
      AlarmEntity alarm, bool updateAlarmManager) async {
    print('Updating alarm: ${alarm.toMap().toString()}');

    alarm = await DateTimeUtils.setNextItemTime(alarm);
    await SqfliteService().updateAlarm(alarm);

    // todo: add alarm to api when have internet connection (no authentication needed, will delete items from api when not been used)

    if (updateAlarmManager) {
      return await AlarmManagerApi.scheduleAlarm(alarm);
    }

    return true;
  }

  @pragma('vm:entry-point')
  static Future<void> deleteAlarm(int id) async {
    print('Delete alarm: ${id}');
    // todo: add alarm to api when have internet connection (no authentication needed, will delete items from api when not been used)

    await AlarmManagerApi.stopAlarm(id);
    await SqfliteService().deleteAlarm(id);
  }
}

  // @pragma('vm:entry-point')
  // static Future stopAlarm(int id) async {
  //   SqfliteService dbHelper = SqfliteService();
  //   AlarmEntity? alarmItem = await dbHelper.getAlarm(id);

  //   if (alarmItem == null) {
  //     return null;
  //   }

  //   debugPrint('Stopping alarm with id: ${alarmItem.id}');
  //   // await AlarmNotificationApi.init();
  //   // await AndroidAlarmManager.initialize();
  //   // await AndroidAlarmManager.initialize();

  //   // AlarmNotificationApi.cancelUpcomingNotification(id);
  //   // AlarmNotificationApi.cancelSnoozingNotification(id);
  //   // await AndroidAlarmManager.cancel(AlarmNotificationApi.getUpcomingId(id));
  //   // await AndroidAlarmManager.cancel(AlarmNotificationApi.getSnoozingId(id));
  //   // await AndroidAlarmManager.cancel(id);
  //   await FlutterForegroundTask.stopService();

  //   // custom data update
  //   await SharedPreferencesService.removeActiveAlarmId();
  //   // todo: add alarm to api when have internet connection (no authentication needed, will delete items from api when not been used)

  //   // Set next alarm if alarm is recurring
  //   if (!alarmItem.enabled) {
  //     // || item.scheduledDays.isEmpty) {
  //     return;
  //   }

  //   alarmItem = await DateTimeUtils.setNextItemTime(alarmItem);
  //   await SqfliteService().updateAlarm(alarmItem);
  //   await AlarmManagerApi.scheduleAlarm(alarmItem);
  // }