import 'dart:async';
import 'dart:io';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mindr.alarm/src/services/alarmNotificationApi.dart';
import 'package:mindr.alarm/src/services/shared_preferences_service.dart';
import 'package:mindr.alarm/src/alarm_page/alarm_screen.dart';
import 'package:mindr.alarm/src/alarm_page/alarm_list_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _configureLocalTimeZone() async {
  if (kIsWeb || Platform.isLinux) {
    return;
  }
  tz.initializeTimeZones();
  final String? timeZoneName = await FlutterTimezone.getLocalTimezone();

  tz.setLocalLocation(tz.getLocation(timeZoneName!));
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await AlarmNotificationApi.init();
  await AndroidAlarmManager.initialize();

  // // If you're going to use other Firebase services in the background, such as Firestore,
  // // make sure you call `initializeApp` before using other Firebase services.
  // await Firebase.initializeApp();

  // TODO: update, create or delete alarm here based on the message data.
  // This trigger comes from the database trigger on the server side.
  // from background state, application is (not running)/killed

  print(
      "Handling a background message: ${message.messageId} data: ${message.toMap()}");
}

Future<void> _firebaseMessagingForegroundHandler(RemoteMessage message) async {
  // TODO: update, create or delete alarm here based on the message data.
  // This trigger comes from the database trigger on the server side.
  // from foreground state, application is still running

  print(
      "Handling a foreground message: ${message.messageId} data: ${message.toMap()}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AlarmNotificationApi.init();
  await AndroidAlarmManager.initialize();
  await _configureLocalTimeZone();

  // Used for MINDR database sync:
  // https://console.firebase.google.com/u/0/project/mindr-samples-alarm/notification/compose
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final fcmToken = await FirebaseMessaging.instance.getToken();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen(_firebaseMessagingForegroundHandler);
  print('fcmToken: $fcmToken');

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
// -

// TODO: When the alarm is fired and the app is STILL in the background, and we click on the alarm notification.
//    The alarm screen is not shown to put the alarm off.
// Debug:
//      Notification ssed to run in foreground service as it has not been removed from the background.

// TODO: Show alarm screen when the alarm is fired, to stop the alarm.

