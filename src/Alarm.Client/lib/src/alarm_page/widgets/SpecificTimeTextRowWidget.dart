import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/AlarmEntityView.dart';
import '../../utils/DateTimeUtils.dart';

class SpecificTimeTextRowWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AlarmEntityView>(
      builder: (context, alarmEntityView, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Next',
            labelStyle: TextStyle(color: Colors.white),
            border: InputBorder.none,
          ),
          child: Text(
            DateTimeUtils.formatDateTimeAsDate(alarmEntityView.time),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
