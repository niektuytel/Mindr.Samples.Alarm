import 'dart:convert';

import 'package:mindr.alarm/src/models/alarm_brief_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
