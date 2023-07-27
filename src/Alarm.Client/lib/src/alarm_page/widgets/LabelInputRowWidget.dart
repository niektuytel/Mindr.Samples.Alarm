import 'package:flutter/material.dart';
import '../../models/AlarmEntity.dart';
import '../../services/alarmManagerApi.dart';

class LabelInputRowWidget extends StatelessWidget {
  final AlarmEntity item;

  LabelInputRowWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: item.label,
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
          item.label = value;
          await AlarmManagerApi.updateAlarm(item, false);
        },
      ),
    );
  }
}
