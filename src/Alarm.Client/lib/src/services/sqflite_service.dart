import 'package:client/src/models/alarm_item_view.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;
import 'dart:io' as io;
import 'dart:async';

import 'alarm_client.dart';

class SqfliteService {
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
    var db = await openDatabase(path1, version: 1, onCreate: _onCreateAlarm);
    return db;
  }

  Future _onCreateAlarm(Database db, int version) async {
    await db.execute("CREATE TABLE alarm("
        "id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "time TEXT, "
        "label TEXT, "
        "scheduledDays TEXT, "
        "isEnabled INTEGER, "
        "sound TEXT, "
        "vibrationChecked INTEGER, "
        "syncWithMindr INTEGER)");
  }

  Future<List<AlarmItemView>> getAlarms() async {
    var dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.query('alarm');
    List<AlarmItemView> alarms = [];
    if (maps.length > 0) {
      for (int i = 0; i < maps.length; i++) {
        alarms.add(AlarmItemView.fromMap(maps[i]));
      }
    }
    return alarms;
  }

  Future<AlarmItemView?> getAlarm(int id) async {
    var dbClient = await db;
    List<Map<String, dynamic>> result =
        await dbClient.query("alarm", where: "id = ?", whereArgs: [id]);

    if (result.length > 0) {
      return AlarmItemView.fromMap(result.first);
    }

    return null;
  }

  Future<int> insertAlarm(AlarmItemView alarm) async {
    var dbClient = await db;
    int? id = Sqflite.firstIntValue(
        await dbClient.rawQuery('SELECT MAX(id)+1 as id FROM alarm'));
    alarm.id = id ?? 1;
    int res = await dbClient.insert("alarm", alarm.toMap());
    return res;
  }

  Future<int> updateAlarm(AlarmItemView alarm) async {
    var dbClient = await db;
    int res = await dbClient
        .update("alarm", alarm.toMap(), where: "id = ?", whereArgs: [alarm.id]);
    return res;
  }

  Future<int> deleteAlarm(int id) async {
    var dbClient = await db;
    int res = await dbClient.rawDelete('DELETE FROM alarm WHERE id = ?', [id]);
    return res;
  }
}
