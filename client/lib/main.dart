import 'dart:async';
import 'dart:io';
// import 'dart:isolate';
// import 'dart:ui';

import 'package:alarm/alarm.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
// import 'package:client/src/alarm_page/alarm_notifications.dart';
import 'package:client/src/alarm_page/alarm_intent_screen.dart';
import 'package:client/src/alarm_page/alarm_page.dart';
// import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_foreground_task/flutter_foreground_task.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:shared_preferences/shared_preferences.dart';

import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
// import 'package:vibration/vibration.dart';

String? selectedNotificationPayload;
Future<void> _configureLocalTimeZone() async {
  if (kIsWeb || Platform.isLinux) {
    return;
  }
  tz.initializeTimeZones();
  final String? timeZoneName = await FlutterTimezone.getLocalTimezone();

  tz.setLocalLocation(tz.getLocation(timeZoneName!));
}

// void onStart() {
//   WidgetsFlutterBinding.ensureInitialized();
//   // // Move your `showNotification` code here
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  await Alarm.init();

  await _configureLocalTimeZone();
  // FlutterForegroundService.initialize(onStart);
  // await AndroidAlarmManager.initialize();
  // final NotificationAppLaunchDetails? notificationAppLaunchDetails = !kIsWeb &&
  //         Platform.isLinux
  //     ? null
  //     : await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  // // get the alarm id from shared preferences
  // SharedPreferences prefs = await SharedPreferences.getInstance();
  // String? pendingPayload = prefs.getString('pendingPayload');
  // print("main.dart pendingPayload:$pendingPayload");

  // Load the payload
  // String initialRoute = AlarmListPage.routeName;
  // if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
  //   selectedNotificationPayload =
  //       notificationAppLaunchDetails!.notificationResponse?.payload;
  //   initialRoute = AlarmScreen.routeName;
  // } else if (pendingPayload != null) {
  //   selectedNotificationPayload = pendingPayload;
  //   initialRoute = AlarmScreen.routeName;
  // }

  runApp(
    MaterialApp(
      initialRoute: AlarmListPage.routeName,
      routes: <String, WidgetBuilder>{
        AlarmListPage.routeName: (_) => AlarmListPage(),
        AlarmScreen.routeName: (context) => const AlarmScreen(),
      },
    ),
  );
}
