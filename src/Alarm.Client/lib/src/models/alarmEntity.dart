import 'dart:ffi';

class AlarmEntity {
  AlarmEntity(this.time);

  int id = 0;
  String label = "test";
  DateTime time;
  List<int> scheduledDays = [];
  bool enabled = true;
  String sound = '';
  bool vibrationChecked = true;
  bool syncWithMindr = false;

  bool isExpanded = false;

  // Convert a AlarmItem into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time':
          '${time.toIso8601String().split('.')[0]}Z', // Append 'Z' for UTC timezone + removes microseconds
      'label': label,
      'scheduledDays':
          scheduledDays.join(','), // Convert list to comma-separated string
      'isEnabled': enabled ? 1 : 0,
      'sound': sound,
      'vibrationChecked': vibrationChecked ? 1 : 0,
      'syncWithMindr': syncWithMindr ? 1 : 0,
    };
  }

  // Create a AlarmItem from a Map.
  AlarmEntity.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        time = DateTime.parse(map['time']),
        label = map['label'],
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
