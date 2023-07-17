import 'dart:ffi';

class AlarmItemView {
  AlarmItemView(
    this.id,
    this.time,
    this.scheduledDays,
    this.enabled,
    this.sound,
    this.vibrationChecked,
    this.syncWithMindr,
  );

  int id;
  String label = "test";
  DateTime time;
  List<int> scheduledDays;
  bool enabled;
  String sound;
  bool vibrationChecked;
  bool syncWithMindr;

  bool isExpanded = false;

  // Convert a AlarmItem into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'time': time.toIso8601String(),
      'scheduledDays':
          scheduledDays.join(','), // Convert list to comma-separated string
      'isEnabled': enabled ? 1 : 0,
      'sound': sound,
      'vibrationChecked': vibrationChecked ? 1 : 0,
      'syncWithMindr': syncWithMindr ? 1 : 0,
    };
  }

  // Create a AlarmItem from a Map.
  AlarmItemView.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        time = DateTime.parse(map['time']),
        scheduledDays =
            map['scheduledDays'] == null || map['scheduledDays'].isEmpty
                ? []
                : (map['scheduledDays'] as String)
                    .split(',')
                    .map((item) => int.parse(item.toString()))
                    .toList(),
        enabled = map['isEnabled'] == 1,
        sound = map['sound'],
        vibrationChecked = map['vibrationChecked'] == 1,
        syncWithMindr = map['syncWithMindr'] == 1;
}
