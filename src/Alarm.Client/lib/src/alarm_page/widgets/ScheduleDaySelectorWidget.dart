import 'package:flutter/cupertino.dart';

import '../../models/AlarmEntity.dart';
import '../../services/alarmManagerApi.dart';

class ScheduleDaySelectorWidget extends StatefulWidget {
  final AlarmEntity item;
  final List<String> dayNames;

  const ScheduleDaySelectorWidget(
      {Key? key, required this.item, required this.dayNames})
      : super(key: key);

  @override
  _ScheduleDaySelectorWidgetState createState() =>
      _ScheduleDaySelectorWidgetState();
}

class _ScheduleDaySelectorWidgetState extends State<ScheduleDaySelectorWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(children: _buildDaySelectors());
  }

  List<Widget> _buildDaySelectors() {
    return List<Widget>.generate(7, (index) {
      bool isScheduled = widget.item.scheduledDays.contains(index + 1);
      return GestureDetector(
        onTap: () async {
          if (isScheduled) {
            widget.item.scheduledDays.remove(index + 1);
          } else {
            widget.item.scheduledDays.add(index + 1);
          }
          // Now update the database
          await AlarmManagerApi.updateAlarm(widget.item, true);
          // After completing database update, update the state.
          setState(() {});
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
            widget.dayNames[index],
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
