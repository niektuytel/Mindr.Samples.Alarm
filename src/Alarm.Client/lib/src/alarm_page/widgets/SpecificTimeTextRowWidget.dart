import 'package:flutter/material.dart';
import '../../models/AlarmEntity.dart';
import '../../utils/DateTimeUtils.dart';

class SpecificTimeTextRowWidget extends StatelessWidget {
  final AlarmEntity item;

  SpecificTimeTextRowWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Next',
          labelStyle: TextStyle(color: Colors.white),
          border: InputBorder.none,
        ),
        child: Text(
          DateTimeUtils.formatDateTimeAsDate(item.time),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
