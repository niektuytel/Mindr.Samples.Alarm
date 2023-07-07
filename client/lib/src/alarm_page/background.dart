import 'dart:async';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:client/src/alarm_page/alarm_intent_screen.dart';
import 'package:flutter/widgets.dart';

import 'alarm_page.dart';

void alarmCallback() {
  // Perform the desired actions when the alarm is triggered
  // This code will run even when the app is not actively opened or running in the background
  print('Alarm triggered!');
}

Future<void> backgroundMain() async {
  await AndroidAlarmManager.initialize();
  runApp(AlarmScreen()); // Replace with your app's main widget
  AndroidAlarmManager.periodic(const Duration(minutes: 1), 0, alarmCallback);
}
