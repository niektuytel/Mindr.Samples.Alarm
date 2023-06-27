import 'dart:ffi';

/// A placeholder class that represents an entity or model.
class AlarmItem {
  AlarmItem(this.id, this.time, this.scheduledDays, this.isEnabled, this.sound,
      this.vibrationChecked, this.syncWithMindr);

  String id;
  DateTime time;
  List<int> scheduledDays;
  bool isEnabled;
  String sound;
  bool vibrationChecked;
  bool syncWithMindr;

  bool isExpanded = false;
}

// Sample test data:
final List<AlarmItem> sampleData = [
  AlarmItem("1", DateTime(2021, 10, 10, 10, 10), [1, 3, 5], true, 'default',
      true, true),
  AlarmItem("2", DateTime(2021, 10, 11, 10, 10), [1, 3, 5], true, 'default',
      true, true),
  AlarmItem("3", DateTime(2021, 10, 12, 10, 10), [1, 3, 5], true, 'default',
      true, true),
  AlarmItem("4", DateTime(2021, 10, 13, 10, 10), [1, 3, 5], false, 'default',
      true, true),
  AlarmItem("5", DateTime(2021, 10, 14, 10, 10), [1, 3, 5], false, 'default',
      true, true),
  AlarmItem("6", DateTime(2021, 10, 15, 10, 10), [1, 3, 5], true, 'default',
      true, true),
  AlarmItem("7", DateTime(2021, 10, 16, 10, 10), [1, 3, 5], true, 'default',
      true, true),
  AlarmItem("8", DateTime(2021, 10, 17, 10, 10), [1, 3, 5], false, 'default',
      true, true),
  AlarmItem("9", DateTime(2021, 10, 18, 10, 10), [1, 3, 5], false, 'default',
      true, true),
  AlarmItem("10", DateTime(2021, 10, 19, 10, 10), [1, 3, 5], false, 'default',
      true, true),
];

// AlarmItem(1, DateTime(2021, 10, 10, 10, 10), [DateTime(2021, 10, 10, 10, 10)], true, true, true),
// AlarmItem(2, DateTime(2021, 10, 10, 10, 10), [DateTime(2021, 10, 10, 10, 10)], true, true, true),
// AlarmItem(3, DateTime(2021, 10, 10, 10, 10), [DateTime(2021, 10, 10, 10, 10)], true, true, true),
// AlarmItem(4, DateTime(2021, 10, 10, 10, 10), [DateTime(2021, 10, 10, 10, 10)], true, true, true),
// AlarmItem(5, DateTime(2021, 10, 10, 10, 10), [DateTime(2021, 10, 10, 10, 10)], true, true, true),
// AlarmItem(6, DateTime(2021, 10, 10, 10, 10), [DateTime(2021, 10, 10, 10, 10)], true, true, true),
// AlarmItem(7, DateTime(2021, 10, 10, 10, 10), [DateTime(2021, 10, 10, 10, 10)], true, true, true),
// AlarmItem(8, DateTime(2021, 10, 10, 10, 10), [DateTime(2021, 10, 10, 10, 10)], false, true, true),
// AlarmItem(9, DateTime(2021, 10, 10, 10, 10), [DateTime(2021, 10, 10, 10, 10)], false, true, true),
// AlarmItem(10, DateTime(2021, 10, 10, 10, 10), [DateTime(2021, 10, 10, 10, 10)], false, true, true),
// AlarmItem(11, DateTime(2021, 10, 10, 10, 10), [DateTime(2021, 10, 10, 10, 10)], false, true, true),
// AlarmItem(12, DateTime(2021, 10, 10, 10, 10), [DateTime(2021, 10, 10, 10, 10)], false, true, true),
// AlarmItem(13, DateTime(2021, 10, 10, 10, 10), [DateTime(2021, 10, 10, 10, 10)], false, true, true),
// AlarmItem(14, DateTime(2021, 10, 10, 10, 10), [DateTime(2021, 10, 10, 10, 10)], false, true, true),
// AlarmItem(15, DateTime(2021, 10, 10, 10, 10), [DateTime(2021, 10, 10, 10, 10)], false, true, true),
// AlarmItem(16, DateTime(2021, 10, 10, 10, 10), [DateTime(2021, 10, 10, 10, 10)], false, true, true),
// AlarmItem(17, DateTime(2021, 10, 10, 10, 10), [DateTime(2021, 10, 10, 10, 10)], false, true, true), 
