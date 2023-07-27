import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../models/AlarmEntity.dart';
import '../../services/alarmManagerApi.dart';

class ScheduleDaysWidget extends StatefulWidget {
  final AlarmEntity item;

  ScheduleDaysWidget({Key? key, required this.item}) : super(key: key);

  @override
  _ScheduleDaysWidgetState createState() => _ScheduleDaysWidgetState();
}

class _ScheduleDaysWidgetState extends State<ScheduleDaysWidget> {
  String getFormattedScheduledDays(List<int> scheduledDays) {
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    List<String> selectedDays = [];

    if (scheduledDays.length == 7) {
      return 'Daily';
    }

    scheduledDays.sort();
    for (int dayIndex in scheduledDays) {
      if (dayIndex >= 1 && dayIndex <= 7) {
        selectedDays.add(dayNames[dayIndex - 1]);
      }
    }

    return selectedDays.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(getFormattedScheduledDays(widget.item.scheduledDays),
            style: const TextStyle(fontSize: 16, color: Colors.white)),
        Switch(
          value: widget.item.enabled,
          onChanged: (newValue) async {
            setState(() => widget.item.enabled = newValue);
            await AlarmManagerApi.updateAlarm(widget.item, true);
          },
          activeColor: Colors.white,
        ),
      ],
    );
  }
}
