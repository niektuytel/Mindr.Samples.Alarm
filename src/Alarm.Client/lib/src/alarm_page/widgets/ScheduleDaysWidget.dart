import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/AlarmEntityView.dart';
import '../../services/alarmManagerApi.dart';

class ScheduleDaysWidget extends StatelessWidget {
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
    final alarmEntityView = Provider.of<AlarmEntityView>(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(getFormattedScheduledDays(alarmEntityView.scheduledDays),
            style: const TextStyle(fontSize: 16, color: Colors.white)),
        Switch(
          value: alarmEntityView.enabled,
          onChanged: (newValue) async {
            alarmEntityView.enabled = newValue;
            await AlarmManagerApi.updateAlarm(
                alarmEntityView.toAlarmEntity(), true);
          },
          activeColor: Colors.white,
        ),
      ],
    );
  }
}
