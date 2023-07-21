import 'dart:async';
import 'dart:io';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:mindr.alarm/src/services/shared_preferences_service.dart';
import 'package:mindr.alarm/src/alarm_page/alarm_screen.dart';
import 'package:mindr.alarm/src/alarm_page/alarm_list_page.dart';
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

// (NEW Features)
// - make alarmmanager work faster and more accurate
//  

// TODO: When now the time is 10:00AM and you set an alarm on 12:03AM, the alarm is not been triggered.
//    The upcomming alarm notification is not shown in the notification bar when the app is removed from the the background. (before 10:03AM)
// Debug:
//     Tested on Redmi 8 see this issue, consent on battery optimization, the issue is resolved. (and testing in debug mode)


// TODO: When set alarm in range of 2 hours from the time it's been set the upcoming alarm notification is shown.
//    But when closing app and removing it from the background, the upcoming alarm notification is removed from notifications. 
// Debug:
//      Tested on Redmi 8 see this issue, still when give consent on battery optimization, the issue is not resolved.

// TODO: When the alarm is fired and the app is in the background, and we click on the alarm notification. 
//    The alarm screen is not shown to put the alarm off.

// TODO: Show alarm screen when the alarm is fired, to stop the alarm.