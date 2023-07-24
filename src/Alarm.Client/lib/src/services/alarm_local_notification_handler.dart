import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mindr.alarm/src/services/shared_preferences_service.dart';

import '../../main.dart';
import '../alarm_page/alarm_screen.dart';
import 'alarm_handler.dart';
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

class LocalNotificationHandler {
  static Future<FlutterLocalNotificationsPlugin>
      GetInitializedNotification() async {
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

    return localNotificationsPlugin;
  }

  static Future<void> Cancel(int alarmId) async {
    var localNotifications = await GetInitializedNotification();
    await localNotifications.cancel(alarmId * 1234);
  }
}
