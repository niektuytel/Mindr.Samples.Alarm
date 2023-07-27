import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mindr.alarm/src/alarm_page/widgets/AlarmCardExpansionWidget.dart';
import 'package:mindr.alarm/src/alarm_page/widgets/scheduleDaysWidget.dart';
import 'package:mindr.alarm/src/alarm_page/widgets/timeSelectorWidget.dart';

import '../../models/AlarmEntity.dart';

class AlarmCardWidget extends StatefulWidget {
  final AlarmEntity item;
  final List<AlarmEntity> items; // added this

  AlarmCardWidget({required this.item, required this.items}); // and this

  @override
  _AlarmCardWidgetState createState() => _AlarmCardWidgetState();
}

class _AlarmCardWidgetState extends State<AlarmCardWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      color: const Color.fromARGB(255, 53, 53, 53),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ExpansionTile(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        title: TimeSelectorWidget(item: widget.item),
        subtitle: ScheduleDaysWidget(item: widget.item),
        trailing: Icon(
          widget.item.isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
          color: Colors.white,
        ),
        onExpansionChanged: (newState) {
          setState(() => widget.item.isExpanded = newState);
        },
        children: [
          AlarmCardExpansionWidget(item: widget.item, items: widget.items)
        ], // here, passed items list
      ),
    );
  }
}
