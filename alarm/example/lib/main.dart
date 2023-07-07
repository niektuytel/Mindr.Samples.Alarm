import 'dart:async';
import 'package:alarm_example/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'alarm/alarm.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Alarm.init(showDebugLogs: true);

  runApp(const MaterialApp(home: ExampleAlarmHomeScreen()));
}
