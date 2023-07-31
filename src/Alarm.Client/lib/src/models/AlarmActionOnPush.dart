import 'dart:convert';

import 'package:mindr.alarm/src/models/alarmEntity.dart';

class AlarmActionOnPush {
  final String? userId;
  final String? actionType;
  final AlarmEntity alarm;

  AlarmActionOnPush({
    required this.userId,
    required this.actionType,
    required this.alarm,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'action_type': actionType,
      'alarm': alarm.toMap(),
    };
  }

  factory AlarmActionOnPush.fromMap(Map<String, dynamic> map) {
    return AlarmActionOnPush(
      userId: map['user_id'],
      actionType: map['action_type'],
      alarm: AlarmEntity.fromMap(map['alarm']),
    );
  }

  String toJson() => json.encode(toMap());

  factory AlarmActionOnPush.fromJson(String source) =>
      AlarmActionOnPush.fromMap(json.decode(source));
}
