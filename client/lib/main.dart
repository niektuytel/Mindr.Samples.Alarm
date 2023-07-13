import 'dart:async';
import 'dart:io';
// import 'dart:isolate';
// import 'dart:ui';

import 'package:alarm/alarm.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
// import 'package:client/src/alarm_page/alarm_notifications.dart';
import 'package:client/src/alarm_page/alarm_intent_screen.dart';
import 'package:client/src/alarm_page/alarm_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

Future<void> _configureLocalTimeZone() async {
  if (kIsWeb || Platform.isLinux) {
    return;
  }
  tz.initializeTimeZones();
  final String? timeZoneName = await FlutterTimezone.getLocalTimezone();

  tz.setLocalLocation(tz.getLocation(timeZoneName!));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  await _configureLocalTimeZone();

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
