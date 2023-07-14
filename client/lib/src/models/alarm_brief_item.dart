import 'dart:ffi';

class AlarmBriefItem {
  AlarmBriefItem(this.id);

  int id;

  // Create a AlarmItem from a Map.
  AlarmBriefItem.fromJson(Map<String, dynamic> map) : id = map['id'];
}
