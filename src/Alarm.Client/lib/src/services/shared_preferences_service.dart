import 'dart:convert';

import 'package:mindr.alarm/src/models/alarmSyncEntity.dart';
import 'package:shared_preferences/shared_preferences.dart';

// TODO: Need to change to more nice way to store data that we can interact with multiple instances.
class SharedPreferencesService {
  static Future<bool> setActiveAlarmItemId(int alarmItemId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setInt("alarm_item_id", alarmItemId);
  }

  static Future<int?> getActiveAlarmItemId() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey("alarm_item_id")) {
      var value = prefs.getInt("alarm_item_id");
      return value;
    }

    return null;
  }

  static Future<bool?> removeActiveAlarmId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove("alarm_item_id");
  }

  static setUpcomingAlarmItemId(int id) {}
}
