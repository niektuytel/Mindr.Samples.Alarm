import 'package:flutter/cupertino.dart';

import 'AlarmEntity.dart';

class AlarmEntityView with ChangeNotifier {
  AlarmEntityView(
    this._id,
    this._time,
    this._scheduledDays,
    this._enabled,
    this._sound,
    this._vibrationChecked,
    this._syncWithMindr,
  );

  int _id;
  String _label = "test";
  DateTime _time;
  List<int> _scheduledDays;
  String _sound;
  bool _vibrationChecked;
  bool _syncWithMindr = false;

  bool _isExpanded = false;
  bool _enabled = true;

  // getters
  int get id => _id;
  String get label => _label;
  DateTime get time => _time;
  List<int> get scheduledDays => _scheduledDays;
  String get sound => _sound;
  bool get vibrationChecked => _vibrationChecked;
  bool get syncWithMindr => _syncWithMindr;
  bool get isExpanded => _isExpanded;
  bool get enabled => _enabled;

  // setters
  set id(int value) {
    _id = value;
    notifyListeners();
  }

  set label(String value) {
    _label = value;
    notifyListeners();
  }

  set time(DateTime value) {
    _time = value;
    notifyListeners();
  }

  set scheduledDays(List<int> value) {
    _scheduledDays = value;
    notifyListeners();
  }

  set sound(String value) {
    _sound = value;
    notifyListeners();
  }

  set vibrationChecked(bool value) {
    _vibrationChecked = value;
    notifyListeners();
  }

  set syncWithMindr(bool value) {
    _syncWithMindr = value;
    notifyListeners();
  }

  set isExpanded(bool value) {
    _isExpanded = value;
    notifyListeners();
  }

  set enabled(bool value) {
    _enabled = value;
    notifyListeners();
  }

  // Convert a AlarmItem into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'time': _time.toIso8601String(),
      'label': _label,
      'scheduledDays':
          _scheduledDays.join(','), // Convert list to comma-separated string
      'isEnabled': _enabled ? 1 : 0,
      'sound': _sound,
      'vibrationChecked': _vibrationChecked ? 1 : 0,
      'syncWithMindr': _syncWithMindr ? 1 : 0,
    };
  }

  // Create a AlarmItem from a Map.
  AlarmEntityView.fromMap(Map<String, dynamic> map)
      : _id = map['id'],
        _time = DateTime.parse(map['time']),
        _label = map['label'],
        _scheduledDays =
            map['scheduledDays'] == null || map['scheduledDays'].isEmpty
                ? []
                : (map['scheduledDays'] as String)
                    .split(',')
                    .map((item) => int.parse(item.toString()))
                    .toList(),
        _enabled = map['isEnabled'] == 1,
        _sound = map['sound'],
        _vibrationChecked = map['vibrationChecked'] == 1,
        _syncWithMindr = map['syncWithMindr'] == 1;

  // Convert a AlarmEntityView to AlarmEntity
  AlarmEntity toAlarmEntity() {
    return AlarmEntity(
      id: _id, // Assume id is converted to string here
      time: _time,
      scheduledDays: _scheduledDays.join(','),
      label: _label,
      sound: _sound,
      isEnabled: _enabled,
      useVibration: _vibrationChecked,
      syncWithMindr: _syncWithMindr,
      // TODO: If you have a connectionId, add it here
    );
  }

  // Create a AlarmEntityView from a AlarmEntity
  AlarmEntityView.fromAlarmEntity(AlarmEntity entity)
      : _id = entity.id, // Assume id is converted from string here
        _time = entity.time,
        _label = entity.label ?? "",
        _scheduledDays = entity.scheduledDays.isEmpty
            ? []
            : (entity.scheduledDays as String)
                .split(',')
                .map((item) => int.parse(item.toString()))
                .toList(),
        _sound = entity.sound ?? "",
        _enabled = entity.isEnabled,
        _vibrationChecked = entity.useVibration,
        _syncWithMindr = entity.syncWithMindr;
}
