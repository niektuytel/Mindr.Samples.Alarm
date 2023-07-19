import 'dart:async';
import 'dart:convert';

import 'package:mindr.alarm/src/models/alarm_item_view.dart';
import 'package:mindr.alarm/src/services/shared_preferences_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../main.dart';
import '../alarm_page/alarm_screen.dart';
import 'alarm_handler.dart';
import 'alarm_handler_foreground_task.dart';
import 'sqflite_service.dart';

final FlutterLocalNotificationsPlugin localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

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

// The callback function should always be a top-level function.
@pragma('vm:entry-point')
void alarmHandler() {
  FlutterForegroundTask.setTaskHandler(AlarmForegroundTaskHandler());
  // // The setTaskHandler function must be called to handle the task in the background.
  // FlutterForegroundTask.setTaskHandler(AlarmTaskHandler());
}

class AlarmService {
  static Future<bool> insertAlarm(AlarmItemView alarm) async {
    print('Insert alarm: ${alarm.toMap().toString()}');
    await SqfliteService().insertAlarm(alarm);

    // todo: add alarm to api when have internet connection (no authentication needed, will delete items from api when not been used)

    return await AlarmHandler.scheduleAlarm(alarm);
  }

  static Future<bool> updateAlarm(AlarmItemView alarm) async {
    print('Updating alarm: ${alarm.toMap().toString()}');
    await SqfliteService().updateAlarm(alarm);

    // todo: add alarm to api when have internet connection (no authentication needed, will delete items from api when not been used)

    return await AlarmHandler.scheduleAlarm(alarm);
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

    var dayOfWeek = DateTime.now().weekday;
    var nextDay = item.scheduledDays.firstWhere(
        (element) => element > dayOfWeek,
        orElse: () => item.scheduledDays.first);

    // calculate the number of days to add
    int daysToAdd =
        nextDay > dayOfWeek ? nextDay - dayOfWeek : 7 - dayOfWeek + nextDay;

    item.time = DateTime.now().add(Duration(days: daysToAdd));

    var updateStatus = await updateAlarm(item);
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
