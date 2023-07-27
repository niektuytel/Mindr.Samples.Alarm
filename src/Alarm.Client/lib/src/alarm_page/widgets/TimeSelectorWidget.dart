import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/AlarmEntityView.dart';
import '../../services/alarmManagerApi.dart';

class TimeSelectorWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final alarmEntityView = Provider.of<AlarmEntityView>(context);
    return GestureDetector(
      onTap: () async {
        TimeOfDay? selectedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(alarmEntityView.time),
        );
        if (selectedTime != null) {
          var time = DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            selectedTime.hour,
            selectedTime.minute,
          );

          alarmEntityView.time = time;
          await AlarmManagerApi.updateAlarm(
              alarmEntityView.toAlarmEntity(), true);
        }
      },
      child: Text(
        DateFormat('h:mm a').format(alarmEntityView.time),
        style: TextStyle(
          fontWeight:
              alarmEntityView.enabled ? FontWeight.bold : FontWeight.normal,
          fontSize: 50,
          color: alarmEntityView.enabled
              ? Colors.white
              : const Color.fromARGB(255, 155, 155, 155),
        ),
      ),
    );
  }
}
