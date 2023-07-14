import 'dart:async';
import 'dart:io';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:client/src/services/shared_preferences_service.dart';
import 'package:client/src/widgets/alarm_screen.dart';
import 'package:client/src/alarm_page/alarm_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

  var alarmItemId =
      await SharedPreferencesService.oneTimeReadActiveAlarmItemId();
  print("main >> ${alarmItemId}");
  String initialRoute = AlarmListPage.routeName;

  if (alarmItemId != null) {
    initialRoute = AlarmScreen.routeName;
  }

  runApp(
    MaterialApp(
      initialRoute: initialRoute,
      navigatorKey: navigatorKey,
      routes: <String, WidgetBuilder>{
        AlarmListPage.routeName: (_) => AlarmListPage(),
        AlarmScreen.routeName: (context) => AlarmScreen(alarmItemId),
      },
    ),
  );
}
