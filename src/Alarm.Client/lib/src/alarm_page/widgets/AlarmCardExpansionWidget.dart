import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mindr.alarm/src/alarm_page/widgets/labelInputRowWidget.dart';
import 'package:mindr.alarm/src/alarm_page/widgets/scheduleDaySelectorWidget.dart';
import 'package:mindr.alarm/src/alarm_page/widgets/switchRowWidget.dart';

import '../../models/AlarmEntity.dart';
import '../../services/alarmManagerApi.dart';
import 'SpecificTimeTextRowWidget.dart';

class AlarmCardExpansionWidget extends StatefulWidget {
  final AlarmEntity item;
  final List<AlarmEntity> items; // added this

  AlarmCardExpansionWidget(
      {Key? key, required this.item, required this.items // and this
      })
      : super(key: key);

  @override
  _AlarmCardExpansionWidgetState createState() =>
      _AlarmCardExpansionWidgetState();
}

class _AlarmCardExpansionWidgetState extends State<AlarmCardExpansionWidget> {
  final dayNames = ["S", "M", "T", "W", "T", "F", "S"];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScheduleDaySelectorWidget(item: widget.item, dayNames: dayNames),
          LabelInputRowWidget(item: widget.item),
          SpecificTimeTextRowWidget(item: widget.item),
          SwitchRowWidget(
            value: widget.item.vibrationChecked,
            text: 'Vibration',
            onChanged: (bool? newValue) async {
              setState(() => widget.item.vibrationChecked = newValue!);
              await AlarmManagerApi.updateAlarm(widget.item, false);
            },
          ),
          SwitchRowWidget(
            value: widget.item.syncWithMindr,
            text: 'Connected to mindr',
            onChanged: (bool? newValue) async {
              setState(() => widget.item.syncWithMindr = newValue!);
              await AlarmManagerApi.updateAlarm(widget.item, false);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    await AlarmManagerApi.deleteAlarm(widget.item.id);
                    widget.items.remove(widget.item); // Now this should work
                    setState(() {});
                  },
                  icon: Icon(Icons.delete, color: Colors.white),
                  label: Text(
                    'Delete',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
