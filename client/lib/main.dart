import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:alarm/alarm.dart';
import 'package:client/src/alarm_page/alarm_notifications.dart';
import 'package:client/src/alarm_page/alarm_intent_screen.dart';
import 'package:client/src/alarm_page/alarm_page.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:vibration/vibration.dart';

String? selectedNotificationPayload;
Future<void> _configureLocalTimeZone() async {
  if (kIsWeb || Platform.isLinux) {
    return;
  }
  tz.initializeTimeZones();
  final String? timeZoneName = await FlutterTimezone.getLocalTimezone();

  tz.setLocalLocation(tz.getLocation(timeZoneName!));
}

void onStart() {
  WidgetsFlutterBinding.ensureInitialized();
  // // Move your `showNotification` code here
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // FlutterForegroundService.initialize(onStart);
  await Alarm.init();
  // await AndroidAlarmManager.initialize();
  await _configureLocalTimeZone();

  final NotificationAppLaunchDetails? notificationAppLaunchDetails = !kIsWeb &&
          Platform.isLinux
      ? null
      : await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  // get the alarm id from shared preferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? pendingPayload = prefs.getString('pendingPayload');
  print("main.dart pendingPayload:$pendingPayload");

  // Load the payload
  String initialRoute = AlarmListPage.routeName;
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
      initialRoute: initialRoute,
      routes: <String, WidgetBuilder>{
        AlarmListPage.routeName: (_) => AlarmListPage(),
        AlarmScreen.routeName: (_) => AlarmScreen(),
        '/resume-route': (context) => const ResumeRoutePage(),
      },
    ),
  );
}

////////////////////////// FOREGROUND SERVICES //////////////////////////

// The callback function should always be a top-level function.
@pragma('vm:entry-point')
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  int _eventCount = 0;

  // Called when the task is started.
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;

    // Sound
    final audioPlayer = AudioPlayer();
    Duration? audioDuration = await audioPlayer.setAsset('assets/marimba.mp3');
    audioPlayer.setLoopMode(LoopMode.all);
    audioPlayer.play();
    Timer(Duration(minutes: 20), () async {
      // Stop playback after 20 minutes
      await audioPlayer.stop();
      await AudioPlayer.clearAssetCache();
    });

    // You can use the getData function to get the stored data.
    final customData =
        await FlutterForegroundTask.getData<String>(key: 'customData');
    print('customData: $customData');
  }

  // Called every [interval] milliseconds in [ForegroundTaskOptions].
  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    FlutterForegroundTask.updateService(
      notificationTitle: 'MyTaskHandler',
      notificationText: 'eventCount: $_eventCount',
    );

    // Vibrate 1x
    Vibration.vibrate();

    // Send data to the main isolate.
    sendPort?.send(_eventCount);

    _eventCount++;
  }

  // Called when the notification button on the Android platform is pressed.
  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    print('onDestroy');
  }

  // Called when the notification button on the Android platform is pressed.
  @override
  void onNotificationButtonPressed(String id) {
    print('onNotificationButtonPressed >> $id');
  }

  // Called when the notification itself on the Android platform is pressed.
  //
  // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
  // this function to be called.
  @override
  void onNotificationPressed() {
    // Note that the app will only route to "/resume-route" when it is exited so
    // it will usually be necessary to send a message through the send port to
    // signal it to restore state when the app is already started.
    FlutterForegroundTask.launchApp("/resume-route");
    _sendPort?.send('onNotificationPressed');
  }
}

// class ExampleApp extends StatelessWidget {
//   const ExampleApp({Key? key}) : super(key: key);
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       initialRoute: '/',
//       routes: {
//         '/': (context) => const ExamplePage(),
//         '/resume-route': (context) => const ResumeRoutePage(),
//       },
//     );
//   }
// }

// class ExamplePage extends StatefulWidget {
//   const ExamplePage({Key? key}) : super(key: key);
//   @override
//   State<StatefulWidget> createState() => _ExamplePageState();
// }

// class _ExamplePageState extends State<ExamplePage> {
//   ReceivePort? _receivePort;
//   int alarmId = 0;
//   Future<void> _requestPermissionForAndroid() async {
//     if (!Platform.isAndroid) {
//       return;
//     }
//     // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
//     // onNotificationPressed function to be called.
//     //
//     // When the notification is pressed while permission is denied,
//     // the onNotificationPressed function is not called and the app opens.
//     //
//     // If you do not use the onNotificationPressed or launchApp function,
//     // you do not need to write this code.
//     if (!await FlutterForegroundTask.canDrawOverlays) {
//       // This function requires `android.permission.SYSTEM_ALERT_WINDOW` permission.
//       await FlutterForegroundTask.openSystemAlertWindowSettings();
//     }
//     // Android 12 or higher, there are restrictions on starting a foreground service.
//     //
//     // To restart the service on device reboot or unexpected problem, you need to allow below permission.
//     if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
//       // This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
//       await FlutterForegroundTask.requestIgnoreBatteryOptimization();
//     }
//     // Android 13 and higher, you need to allow notification permission to expose foreground service notification.
//     final NotificationPermission notificationPermissionStatus =
//         await FlutterForegroundTask.checkNotificationPermission();
//     if (notificationPermissionStatus != NotificationPermission.granted) {
//       await FlutterForegroundTask.requestNotificationPermission();
//     }
//   }

//   void _initForegroundTask() {
//     FlutterForegroundTask.init(
//       androidNotificationOptions: AndroidNotificationOptions(
//         id: 500,
//         channelId: 'notification_channel_id',
//         channelName: 'Foreground Notification',
//         channelDescription:
//             'This notification appears when the foreground service is running.',
//         channelImportance: NotificationChannelImportance.LOW,
//         priority: NotificationPriority.LOW,
//         iconData: const NotificationIconData(
//           resType: ResourceType.mipmap,
//           resPrefix: ResourcePrefix.ic,
//           name: 'launcher',
//           backgroundColor: Colors.orange,
//         ),
//         buttons: [
//           const NotificationButton(
//             id: 'sendButton',
//             text: 'Send',
//             textColor: Colors.orange,
//           ),
//           const NotificationButton(
//             id: 'testButton',
//             text: 'Test',
//             textColor: Colors.grey,
//           ),
//         ],
//       ),
//       iosNotificationOptions: const IOSNotificationOptions(
//         showNotification: true,
//         playSound: false,
//       ),
//       foregroundTaskOptions: const ForegroundTaskOptions(
//         interval: 5000,
//         isOnceEvent: false,
//         autoRunOnBoot: true,
//         allowWakeLock: true,
//         allowWifiLock: true,
//       ),
//     );
//   }

//   Future<bool> _startForegroundTask() async {
//     // You can save data using the saveData function.
//     await FlutterForegroundTask.saveData(key: 'customData', value: 'hello');

//     // Register the receivePort before starting the service.
//     final ReceivePort? receivePort = FlutterForegroundTask.receivePort;
//     final bool isRegistered = _registerReceivePort(receivePort);
//     if (!isRegistered) {
//       print('Failed to register receivePort!');
//       return false;
//     }

//     if (await FlutterForegroundTask.isRunningService) {
//       return FlutterForegroundTask.restartService();
//     } else {
//       return FlutterForegroundTask.startService(
//         notificationTitle: 'Foreground Service is running',
//         notificationText: 'Tap to return to the app',
//         callback: startCallback,
//       );
//     }
//   }

//   Future<bool> _stopForegroundTask() {
//     return FlutterForegroundTask.stopService();
//   }

//   bool _registerReceivePort(ReceivePort? newReceivePort) {
//     if (newReceivePort == null) {
//       return false;
//     }

//     _closeReceivePort();

//     _receivePort = newReceivePort;
//     _receivePort?.listen((data) {
//       if (data is int) {
//         print('eventCount: $data');
//       } else if (data is String) {
//         if (data == 'onNotificationPressed') {
//           Navigator.of(context).pushNamed('/resume-route');
//         }
//       } else if (data is DateTime) {
//         print('timestamp: ${data.toString()}');
//       }
//     });

//     return _receivePort != null;
//   }

//   void _closeReceivePort() {
//     _receivePort?.close();
//     _receivePort = null;
//   }

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await _requestPermissionForAndroid();
//       _initForegroundTask();

//       // You can get the previous ReceivePort without restarting the service.
//       if (await FlutterForegroundTask.isRunningService) {
//         final newReceivePort = FlutterForegroundTask.receivePort;
//         _registerReceivePort(newReceivePort);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _closeReceivePort();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // A widget that prevents the app from closing when the foreground service is running.
//     // This widget must be declared above the [Scaffold] widget.
//     return WithForegroundTask(
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('Flutter Foreground Task'),
//           centerTitle: true,
//         ),
//         body: _buildContentView(),
//       ),
//     );
//   }

//   Widget _buildContentView() {
//     buttonBuilder(String text, {VoidCallback? onPressed}) {
//       return ElevatedButton(
//         onPressed: onPressed,
//         child: Text(text),
//       );
//     }

//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           buttonBuilder('start', onPressed: _startForegroundTask),
//           buttonBuilder('stop', onPressed: _stopForegroundTask),
//         ],
//       ),
//     );
//   }
// }

class ResumeRoutePage extends StatelessWidget {
  const ResumeRoutePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Route'),
        centerTitle: true,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate back to first route when tapped.
            Navigator.of(context).pop();
          },
          child: const Text('Go back!'),
        ),
      ),
    );
  }
}
