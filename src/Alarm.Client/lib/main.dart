import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:mindr.alarm/src/models/AlarmActionOnPush.dart';
import 'package:mindr.alarm/src/models/alarmEntity.dart';
import 'package:mindr.alarm/src/services/alarmManagerApi.dart';
// import 'package:mindr.alarm/src/services/alarmNotificationApi.dart';
import 'package:mindr.alarm/src/services/shared_preferences_service.dart';
// import 'package:mindr.alarm/src/alarm_page/alarm_screen.dart';
import 'package:mindr.alarm/src/alarm_page/alarm_list_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:path_provider_android/path_provider_android.dart';
import 'package:path_provider_ios/path_provider_ios.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

const isolateName = 'alarm_isolate';
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
  WidgetsFlutterBinding.ensureInitialized();
  await _configureLocalTimeZone();
  // DartPluginRegistrant.ensureInitialized();
  // if (Platform.isAndroid) PathProviderAndroid.registerWith();
  // if (Platform.isIOS) PathProviderIOS.registerWith();

  // // Initialize the MethodChannel here
  // MethodChannel('com.mindr.alarm/alarm_trigger')
  //     .setMethodCallHandler((call) async {
  //   // Handle potential callbacks if needed.
  // });

  print(
      "Handling a background message: ${message.messageId} data: ${message.toMap()}");

  var alarmOnPush = AlarmActionOnPush.fromMap(message.data);
  if (alarmOnPush.actionType == 'create') {
    var alarm = AlarmEntity(alarmOnPush.alarm.time);
    alarm.label = alarmOnPush.alarm.label;
    alarm.scheduledDays = alarmOnPush.alarm.scheduledDays;
    alarm.sound = alarmOnPush.alarm.sound;
    alarm.vibrationChecked = alarmOnPush.alarm.vibrationChecked;
    alarm.syncWithMindr = true;

    // Serialize the AlarmEntity object and send it to the main isolate.
    final sendPort = IsolateNameServer.lookupPortByName(isolateName);
    sendPort?.send(json.encode(alarm.toMap()));

    // Register the callback dispatcher for background execution
    // final callback = PluginUtilities.getCallbackHandle(callbackDispatcher);
    await callbackDispatcher(alarm);
    // await AlarmManagerApi.setAlarm(alarm);
  }
}

// This trigger comes from the database trigger on the server side.
Future<void> _firebaseMessagingForegroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureLocalTimeZone();

  print("Handle a foreground: ${message.messageId} data: ${message.toMap()}");

  var alarmOnPush = AlarmActionOnPush.fromMap(message.data);
  if (alarmOnPush.actionType == 'create') {
    AlarmManagerApi.insertAlarmOnPush(alarmOnPush.alarm);
  }

  // TODO: update or delete alarm here based on the message data.
}

void _isolateMain(RootIsolateToken rootIsolateToken) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
  // SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  print("_isolateMain");
}

void main() async {
  RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
  Isolate.spawn(_isolateMain, rootIsolateToken);

  WidgetsFlutterBinding.ensureInitialized();
  // await AlarmNotificationApi.init();
  // await AndroidAlarmManager.initialize();
  await _configureLocalTimeZone();

  // Used for MINDR database sync:
  // https://console.firebase.google.com/u/0/project/mindr-samples-alarm/notification/compose
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // final fcmToken = await FirebaseMessaging.instance.getToken();
  // print('fcmToken: $fcmToken');

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen(_firebaseMessagingForegroundHandler);
  print('set firebase listeners');

  var alarmItemId = await SharedPreferencesService.getActiveAlarmItemId();
  print("main >> ${alarmItemId}");

  String initialRoute = AlarmListPage.routeName;
  // if (alarmItemId != null) {
  //   initialRoute = '${AlarmScreen.routeName}/$alarmItemId';
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
        }
        // else if ('/${pathElements[1]}' == AlarmScreen.routeName &&
        //     pathElements.length > 2) {
        //   var alarmId = int.parse(pathElements[2]);
        //   return MaterialPageRoute(builder: (context) => AlarmScreen(alarmId));
        // }

        return null;
      },
    ),
  );
}

@pragma('vm:entry-point')
Future<void> callbackDispatcher(AlarmEntity alarm) async {
  WidgetsFlutterBinding.ensureInitialized();

  final data = jsonEncode(alarm.toMap()); //_background');

  const MethodChannel _backgroundChannel =
      MethodChannel('com.mindr.alarm/alarm_trigger');

  print('callbackDispatcher data: $data');
  await _backgroundChannel.invokeMethod('scheduleAlarm', {
    'alarm': jsonEncode(alarm.toMap()),
  });
}

// (NEW Features)
// -

// TODO: When the alarm is fired and the app is STILL in the background, and we click on the alarm notification.
//    The alarm screen is not shown to put the alarm off. (shared preferences issue)
// Debug:
//      Notification ssed to run in foreground service as it has not been removed from the background.

// TODO: Show alarm screen when the alarm is fired, to stop the alarm.

// To integrate OpenID Connect (OIDC) into your Flutter Android application for
// user authentication, you'll typically use a library or SDK to help manage the
//details of the protocol. One common library used in Flutter apps for this purpose is AppAuth.

// Here's a high-level overview of the process:

// Create an Auth Provider: First, you'll need to set up an account with an OpenID Connect provider,
// which could be a service like Google, Okta, or Azure AD.

// Register Your App: After creating an account, you'll need to register your application.
// This will typically involve providing some information about your app, such as its name and
// possibly the logo, and you'll get a client ID in return. You will also need to set up a redirect URI at this point.

// Set Up a Redirect URI: For mobile applications, you don't use an HTTP redirect URI. Instead,
// you use a custom scheme that opens your app when visited. For Android apps, this
// typically looks like com.yourapp.package:/.

// Implement OIDC in Your App: Next, you'll use an OIDC library in your application code.
// With Flutter, the AppAuth library is a common choice. You'll initialize the library
// with your client ID and redirect URI, and then use it to send the user to the login page and handle the response.

// Here's some example code that shows how this might look:

// dart
// Copy code
// import 'package:app_auth/app_auth.dart';
// import 'package:flutter/material.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         body: Center(
//           child: RaisedButton(
//             onPressed: () async {
//               final appAuth = AppAuth();
//               final result = await appAuth.authorizeAndExchangeCode(
//                 AuthorizationTokenRequest(
//                   '<client_id>',
//                   '<redirect_url>',
//                   issuer: '<issuer_url>',
//                   scopes: ['openid', 'profile', 'email'],
//                 ),
//               );

//               print('Access token: ${result.accessToken}');
//             },
//             child: Text('Login with OIDC'),
//           ),
//         ),
//       ),
//     );
//   }
// }
// In this code, <client_id> is the ID you received when you registered your app,
//<redirect_url> is the custom scheme you set up, and <issuer_url> is the URL of your OIDC provider's server.

// Handle the Redirect URI: After the user logs in, the OIDC provider will redirect them
//to your redirect URI. Your app needs to handle this URI and extract the authorization code from it.
//This will typically be handled by your OIDC library.
// Note: You will need to register the custom URL scheme in your AndroidManifest.xml file.

// This is a very simplified view of the process, and actual implementation can get quite complex,
//especially when you take into account things like token renewal, error handling, and storing tokens securely.
//It's recommended to thoroughly understand the OIDC flow and best practices before implementing this in a production application.
