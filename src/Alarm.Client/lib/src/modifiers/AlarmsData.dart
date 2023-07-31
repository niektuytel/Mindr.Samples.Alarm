import 'package:flutter/material.dart';

import '../models/alarmEntity.dart';

class AlarmsData extends ChangeNotifier {
  List<AlarmEntity> alarms = [];

  void addAlarm(AlarmEntity alarm) {
    alarms.add(alarm);
    notifyListeners();
  }
}
