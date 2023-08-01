import 'dart:convert';

class AlarmActionOnPush {
  final String? userId;
  final String? actionType;
  final AlarmOnPush alarm;

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
      alarm: AlarmOnPush.fromMap(json.decode(map['alarm'])),
    );
  }

  String toJson() => json.encode(toMap());

  factory AlarmActionOnPush.fromJson(String source) =>
      AlarmActionOnPush.fromMap(json.decode(source));
}

class AlarmOnPush {
  AlarmOnPush(
    this.id,
    this.time,
    this.label,
    this.scheduledDays,
    this.sound,
    this.vibrationChecked,
  );

  int id;
  String label = "test";
  DateTime time;
  List<int> scheduledDays;
  String sound;
  bool vibrationChecked;

  bool isExpanded = false;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time': time.toIso8601String(),
      'label': label,
      'scheduled_days': scheduledDays,
      'sound': sound,
      'vibration_checked': vibrationChecked
    };
  }

  factory AlarmOnPush.fromMap(Map<String, dynamic> map) {
    return AlarmOnPush(
      map['id'],
      DateTime.parse(map['time']),
      map['label'],
      List<int>.from(map['scheduled_days'] ?? []),
      map['sound'],
      map['vibration_checked'],
    );
  }
}
