import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/AlarmEntity.dart';
import '../../services/alarmManagerApi.dart';

class TimeSelectorWidget extends StatefulWidget {
  final AlarmEntity item;

  TimeSelectorWidget({required this.item});

  @override
  _TimeSelectorWidgetState createState() => _TimeSelectorWidgetState();
}

class _TimeSelectorWidgetState extends State<TimeSelectorWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        TimeOfDay? selectedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(widget.item.time),
        );
        if (selectedTime != null) {
          setState(() {
            var time = DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
              selectedTime.hour,
              selectedTime.minute,
            );

            widget.item.time = time;
          });
          await AlarmManagerApi.updateAlarm(widget.item, true);
        }
      },
      child: Text(
        DateFormat('h:mm a').format(widget.item.time),
        style: TextStyle(
          fontWeight: widget.item.enabled ? FontWeight.bold : FontWeight.normal,
          fontSize: 50,
          color: widget.item.enabled
              ? Colors.white
              : const Color.fromARGB(255, 155, 155, 155),
        ),
      ),
    );
  }
}
