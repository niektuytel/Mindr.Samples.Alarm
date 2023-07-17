import 'dart:async';
import 'dart:io';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:client/src/services/shared_preferences_service.dart';
import 'package:client/src/alarm_page/alarm_screen.dart';
import 'package:client/src/alarm_page/alarm_list_page.dart';
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

  var alarmItemId = await SharedPreferencesService.getActiveAlarmItemId();
  print("main >> ${alarmItemId}");

  String initialRoute = AlarmListPage.routeName;
  if (alarmItemId != null) {
    initialRoute = '${AlarmScreen.routeName}/$alarmItemId';
  }

  // var initialRoute = WidgetsBinding.instance?.window.defaultRouteName ?? AlarmListPage.routeName;
  // var pathElements = initialRoute.split('/');

  // int? alarmItemId;
  // if (pathElements.length > 2 && pathElements[1] == AlarmScreen.routeName) {
  //   alarmItemId = int.tryParse(pathElements[2]);
  //   if (alarmItemId == null) {
  //     // Handle error in parsing alarmItemId
  //     initialRoute = AlarmListPage.routeName;
  //   }
  // }

  runApp(
    MaterialApp(
      initialRoute: initialRoute,
      navigatorKey: navigatorKey,
      onGenerateRoute: (RouteSettings settings) {
        final List<String>? pathElements = settings.name?.split('/');
        print('pathelements:${pathElements}');

        if (pathElements == null ||
            pathElements[1] == '' ||
            pathElements.length < 2) {
          return MaterialPageRoute(builder: (context) => AlarmListPage());
        }

        if ('/${pathElements[1]}' == AlarmListPage.routeName) {
          return MaterialPageRoute(builder: (context) => AlarmListPage());
        } else if ('/${pathElements[1]}' == AlarmScreen.routeName &&
            pathElements.length > 2) {
          var alarmId = int.parse(pathElements[2]);
          return MaterialPageRoute(builder: (context) => AlarmScreen(alarmId));
        }
        return null;
      },
    ),
  );
}
