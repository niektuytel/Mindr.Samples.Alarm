import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/AlarmEntityView.dart';
import '../../services/alarmManagerApi.dart';

class LabelInputRowWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AlarmEntityView>(
      builder: (context, alarmEntity, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TextFormField(
          initialValue: alarmEntity.label,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Label',
            labelStyle: TextStyle(color: Colors.white),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
          onChanged: (value) async {
            alarmEntity.label = value;
            await AlarmManagerApi.updateAlarm(
                alarmEntity.toAlarmEntity(), false);
          },
        ),
      ),
    );
  }
}
