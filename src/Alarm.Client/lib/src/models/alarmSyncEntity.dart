import 'package:flutter/foundation.dart';

class AlarmSyncEntity {
  AlarmSyncEntity({
    required this.id,
    required this.userId,
    this.connectionId,
    required this.time,
    this.scheduledDays = "",
    this.label,
    this.sound,
    this.isEnabled = true,
    this.useVibration = true,
  });

  final String id;
  final String userId;
  final String? connectionId;
  final DateTime time;
  final String scheduledDays;
  final String? label;
  final String? sound;
  final bool isEnabled;
  final bool useVibration;

  AlarmSyncEntity.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        userId = json['userId'],
        connectionId = json['connectionId'],
        time = DateTime.parse(json['time']),
        scheduledDays = json['scheduledDays'],
        label = json['label'],
        sound = json['sound'],
        isEnabled = json['isEnabled'],
        useVibration = json['useVibration'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'connectionId': connectionId,
        'time': time.toIso8601String(),
        'scheduledDays': scheduledDays,
        'label': label,
        'sound': sound,
        'isEnabled': isEnabled,
        'useVibration': useVibration,
      };
}
