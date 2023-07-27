import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mindr.alarm/src/alarm_page/widgets/AlarmCardExpansionWidget.dart';
import 'package:mindr.alarm/src/alarm_page/widgets/scheduleDaysWidget.dart';
import 'package:mindr.alarm/src/alarm_page/widgets/timeSelectorWidget.dart';
import 'package:provider/provider.dart';

import '../../models/AlarmEntityView.dart';

// class AlarmCardWidget extends StatefulWidget {
//   final AlarmEntityView item;
//   final List<AlarmEntityView> items; // added this

//   AlarmCardWidget({required this.item, required this.items}); // and this

//   @override
//   _AlarmCardWidgetState createState() => _AlarmCardWidgetState();
// }

// class _AlarmCardWidgetState extends State<AlarmCardWidget> {
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.all(8.0),
//       color: const Color.fromARGB(255, 53, 53, 53),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10.0),
//       ),
//       child: ExpansionTile(
//         clipBehavior: Clip.antiAliasWithSaveLayer,
//         title: TimeSelectorWidget(item: widget.item),
//         subtitle: ScheduleDaysWidget(item: widget.item),
//         trailing: Icon(
//           widget.item.isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
//           color: Colors.white,
//         ),
//         onExpansionChanged: (newState) {
//           setState(() => widget.item.isExpanded = newState);
//         },
//         children: [
//           AlarmCardExpansionWidget(item: widget.item, items: widget.items)
//         ], // here, passed items list
//       ),
//     );
//   }
// }

class AlarmCardWidget extends StatelessWidget {
  final AlarmEntityView alarmEntityView;
  final List<AlarmEntityView> alarmEntities;

  AlarmCardWidget(this.alarmEntityView, this.alarmEntities);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AlarmEntityView>(
      create: (context) => alarmEntityView,
      child: Consumer<AlarmEntityView>(
        builder: (context, alarm, _) {
          return Card(
            margin: const EdgeInsets.all(8.0),
            color: const Color.fromARGB(255, 53, 53, 53),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: ExpansionTile(
              clipBehavior: Clip.antiAliasWithSaveLayer,
              title: TimeSelectorWidget(),
              subtitle: ScheduleDaysWidget(),
              trailing: Icon(
                alarm.isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: Colors.white,
              ),
              onExpansionChanged: (newState) {
                alarm.isExpanded = newState; // Update the state
              },
              children: [
                AlarmCardExpansionWidget(alarmEntities: alarmEntities)
              ],
            ),
          );
        },
      ),
    );
  }
}
