import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mindr.alarm/src/alarm_page/widgets/labelInputRowWidget.dart';
import 'package:mindr.alarm/src/alarm_page/widgets/scheduleDaySelectorWidget.dart';
import 'package:mindr.alarm/src/alarm_page/widgets/switchRowWidget.dart';
import 'package:provider/provider.dart';

import '../../models/AlarmEntityView.dart';
import '../../services/alarmManagerApi.dart';
import 'SpecificTimeTextRowWidget.dart';

class AlarmCardExpansionWidget extends StatelessWidget {
  final List<AlarmEntityView> alarmEntities;

  AlarmCardExpansionWidget({required this.alarmEntities});

  @override
  Widget build(BuildContext context) {
    return Consumer<AlarmEntityView>(
      builder: (context, alarmEntityView, _) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScheduleDaySelectorWidget(),
            LabelInputRowWidget(),
            SpecificTimeTextRowWidget(),
            SwitchRowWidget(
              value: alarmEntityView.vibrationChecked,
              text: 'Vibration',
              onChanged: (bool? newValue) async {
                alarmEntityView.vibrationChecked = newValue!;
                await AlarmManagerApi.updateAlarm(
                    alarmEntityView.toAlarmEntity(), false);
              },
            ),
            SwitchRowWidget(
              value: alarmEntityView.syncWithMindr,
              text: 'Connected to mindr',
              onChanged: (bool? newValue) async {
                alarmEntityView.syncWithMindr = newValue!;
                await AlarmManagerApi.updateAlarm(
                    alarmEntityView.toAlarmEntity(), false);
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      await AlarmManagerApi.deleteAlarm(alarmEntityView.id);
                      alarmEntities.remove(alarmEntityView);
                      Provider.of<AlarmEntityView>(context, listen: false)
                          .notifyListeners();
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
      ),
    );
  }
}
