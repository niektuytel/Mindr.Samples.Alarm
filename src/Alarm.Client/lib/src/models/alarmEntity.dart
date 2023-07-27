class AlarmEntity {
  AlarmEntity({
    required this.id,
    this.userId,
    this.connectionId,
    required this.time,
    this.scheduledDays = "",
    this.label,
    this.sound,
    this.isEnabled = true,
    this.useVibration = true,
    this.syncWithMindr = false,
  });

  int id;
  String? userId;
  String? connectionId;
  DateTime time;
  String scheduledDays;
  String? label;
  String? sound;
  bool isEnabled;
  bool useVibration;
  bool syncWithMindr;

  AlarmEntity.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        userId = json['userId'],
        connectionId = json['connectionId'],
        time = DateTime.parse(json['time']),
        scheduledDays = json['scheduledDays'],
        label = json['label'],
        sound = json['sound'],
        isEnabled = json['isEnabled'],
        useVibration = json['useVibration'],
        syncWithMindr = json['syncWithMindr'];

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
        'syncWithMindr': syncWithMindr,
      };
}
