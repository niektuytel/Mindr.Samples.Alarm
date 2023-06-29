import 'package:alarm/src/sample_feature/sample_item.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'dart:io' as io;
import 'dart:async';

import 'alarm_receiver.dart';

class DBHelper {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) {
      return _db!;
    }
    _db = await initDatabase();
    return _db!;
  }

  initDatabase() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path1 = path.join(documentsDirectory.path, 'alarm.db');
    var db = await openDatabase(path1, version: 1, onCreate: _onCreate);
    return db;
  }

  Future _onCreate(Database db, int version) async {
    await db.execute("CREATE TABLE alarm("
        "id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "time TEXT, "
        "scheduledDays TEXT, "
        "isEnabled INTEGER, "
        "sound TEXT, "
        "vibrationChecked INTEGER, "
        "syncWithMindr INTEGER)");
  }

  Future<List<AlarmItem>> getAlarms() async {
    var dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.query('alarm');
    List<AlarmItem> alarms = [];
    if (maps.length > 0) {
      for (int i = 0; i < maps.length; i++) {
        alarms.add(AlarmItem.fromMap(maps[i]));
      }
    }
    return alarms;
  }

  Future<AlarmItem?> getAlarm(int id) async {
    var dbClient = await db;
    List<Map<String, dynamic>> result =
        await dbClient.query("alarm", where: "id = ?", whereArgs: [id]);

    if (result.length > 0) {
      return AlarmItem.fromMap(result.first);
    }

    return null;
  }

  Future<int> insert(AlarmItem alarm) async {
    var dbClient = await db;
    int? id = Sqflite.firstIntValue(
        await dbClient.rawQuery('SELECT MAX(id)+1 as id FROM alarm'));
    alarm.id = id ?? 1;
    int res = await dbClient.insert("alarm", alarm.toMap());

    if (alarm.isEnabled) {
      // // upcoming alarm notification
      // DateTime preAlarmTime = alarm.time.subtract(Duration(hours: 2));
      // await AndroidAlarmManager.oneShotAt(
      //     preAlarmTime, alarm.id, AlarmReceiver.showUpcomingNotification);

      // alarm notification
      //alarm.time.subtract(Duration(hours: 2));
      DateTime alarmTime = DateTime.now().add(Duration(seconds: 15));
      await AndroidAlarmManager.oneShotAt(
          alarmTime, alarm.id, AlarmReceiver.showNotification);
    }

    return res;
  }

  Future<int> update(AlarmItem alarm) async {
    var dbClient = await db;
    int res = await dbClient
        .update("alarm", alarm.toMap(), where: "id = ?", whereArgs: [alarm.id]);

    if (alarm.isEnabled) {
      await AndroidAlarmManager.oneShotAt(
          alarm.time, alarm.id, AlarmReceiver.showNotification);
    } else {
      await AndroidAlarmManager.cancel(alarm.id);
    }

    return res;
  }

  Future<int> delete(int id) async {
    var dbClient = await db;
    int res = await dbClient.rawDelete('DELETE FROM alarm WHERE id = ?', [id]);
    return res;
  }
}
