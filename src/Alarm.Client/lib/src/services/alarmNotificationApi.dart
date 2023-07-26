import 'dart:convert';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:mindr.alarm/src/services/shared_preferences_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../main.dart';
import '../alarm_page/alarm_screen.dart';
import '../models/alarmEntity.dart';
import '../utils/datatimeUtils.dart';
import 'alarmManagerApi.dart';

// This must be a top-level function, outside of any class.
@pragma('vm:entry-point')
Future<void> notificationHandler(NotificationResponse response) async {
  print(
      'Notification handler id:${response.id} payload:${response.payload!} action:${response.actionId}');

  int alarmItemId = jsonDecode(response.payload!)['alarm_id'];
  bool? openAlarmOnClick = jsonDecode(response.payload!)['open_alarm_onclick'];

  // This is called when a notification or its action is tapped.
  if (response.actionId != null) {
    if (response.actionId == 'snooze') {
      await AlarmManagerApi.snoozeAlarm(alarmItemId);
    } else if (response.actionId == 'dismiss') {
      await AlarmManagerApi.stopAlarm(alarmItemId);
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

class AlarmNotificationApi {
  static final _notification = FlutterLocalNotificationsPlugin();
  static final onNotifications = BehaviorSubject<NotificationResponse?>();

  @pragma('vm:entry-point')
  static Future init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const notificationsettings =
        InitializationSettings(android: androidSettings);

    /// when app is closed
    final details = await _notification.getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp) {
      onNotifications.add(details.notificationResponse);
    }

    await _notification.initialize(
      notificationsettings,
      onDidReceiveNotificationResponse: notificationHandler,
      onDidReceiveBackgroundNotificationResponse: notificationHandler,
    );
  }

  static NotificationDetails _getUpcomingDetails(String channelId) {
    var androidDetails = AndroidNotificationDetails(
      channelId,
      'Upcoming Alarm',
      importance: Importance.high,
      priority: Priority.defaultPriority,
      showWhen: true,
      styleInformation: DefaultStyleInformation(true, true),
      ongoing: true,
      autoCancel: false,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction('dismiss', 'Dismiss',
            titleColor: Color.fromRGBO(28, 56, 134, 1), icon: null)
      ],
    );

    return NotificationDetails(
      android: androidDetails,
    );
  }

  static NotificationDetails _getSnoozingDetials(String channelId) {
    var androidDetails = AndroidNotificationDetails(
      channelId,
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

    return NotificationDetails(
      android: androidDetails,
    );
  }

  static String _getBody(String label, DateTime time) {
    var body = label.isEmpty
        ? DateTimeUtils.formatDateTime(time)
        : '${DateTimeUtils.formatDateTime(time)} - $label';

    return body;
  }

  static int getUpcomingId(int id) {
    return (id * 1234);
  }

  static int getSnoozingId(int id) {
    return (id * 1235);
  }

  @pragma('vm:entry-point')
  static Future showUpcomingNotification(
      int upcomingId, Map<String, dynamic> params) async {
    // await AlarmNotificationApi.init();
    var alarmItem = AlarmEntity.fromMap(params);

    if (alarmItem.enabled == false) {
      return false;
    }

    var title = "Upcoming alarm";
    var body = _getBody(alarmItem.label, alarmItem.time);
    var details = _getUpcomingDetails(upcomingId.toString());
    var payload = jsonEncode({
      'alarm_id': alarmItem.id,
      'open_alarm_onclick': true,
    });

    await _notification.show(upcomingId, title, body, details,
        payload: payload);
  }

  @pragma('vm:entry-point')
  static Future showSnoozingNotification(
      int snoozingId, Map<String, dynamic> params) async {
    var alarmItem = AlarmEntity.fromMap(params);

    if (alarmItem.enabled == false) {
      return false;
    }

    var title = "Snoozed alarm";
    var body = _getBody(alarmItem.label, alarmItem.time);
    var details = _getSnoozingDetials(snoozingId.toString());
    var payload = jsonEncode({
      'alarm_id': alarmItem.id,
      'open_alarm_onclick': true,
    });

    await _notification.show(snoozingId, title, body, details,
        payload: payload);
  }

  static void cancelUpcomingNotification(int id) async {
    await _notification.cancel(getUpcomingId(id));
  }

  static void cancelSnoozingNotification(int id) async {
    await _notification.cancel(getSnoozingId(id));
  }

  static void cancelAll() => _notification.cancelAll();
}
