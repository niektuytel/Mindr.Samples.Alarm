import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../models/AlarmEntityView.dart';
import '../../services/alarmManagerApi.dart';

class ScheduleDaySelectorWidget extends StatelessWidget {
  final dayNames = ["S", "M", "T", "W", "T", "F", "S"];

  @override
  Widget build(BuildContext context) {
    return Consumer<AlarmEntityView>(
      builder: (context, alarmEntityView, _) =>
          Row(children: _buildDaySelectors(context, alarmEntityView)),
    );
  }

  List<Widget> _buildDaySelectors(
      BuildContext context, AlarmEntityView alarmEntityView) {
    return List<Widget>.generate(7, (index) {
      bool isScheduled = alarmEntityView.scheduledDays.contains(index + 1);
      return GestureDetector(
        onTap: () async {
          if (isScheduled) {
            alarmEntityView.scheduledDays.remove(index + 1);
          } else {
            alarmEntityView.scheduledDays.add(index + 1);
          }
          // Now update the database
          await AlarmManagerApi.updateAlarm(
              alarmEntityView.toAlarmEntity(), true);
        },
        child: Container(
          width: 30,
          height: 30,
          margin: const EdgeInsets.only(right: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isScheduled
                ? const Color.fromARGB(255, 106, 200, 255)
                : const Color.fromARGB(255, 97, 97, 97),
            shape: BoxShape.circle,
          ),
          child: Text(
            dayNames[index],
            style: TextStyle(
              color: isScheduled
                  ? const Color.fromARGB(255, 44, 44, 44)
                  : const Color.fromARGB(255, 190, 190, 190),
            ),
          ),
        ),
      );
    });
  }
}
