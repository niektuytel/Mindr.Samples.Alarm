import 'package:flutter/material.dart';
import 'package:mindr.alarm/src/models/alarmEntity.dart';
import 'package:slidable_button/slidable_button.dart';

import '../services/alarmManagerApi.dart';
import '../services/alarmNotificationApi.dart';
import '../services/sqflite_service.dart';
import '../utils/datetimeUtils.dart';

class AlarmScreen extends StatefulWidget {
  // below 0 is wrong value
  final int? alarmItemId;

  const AlarmScreen(this.alarmItemId) : super();

  static const String routeName = '/alarm_screens';

  @override
  _AlarmScreenState createState() => _AlarmScreenState(alarmItemId!);
}

class _AlarmScreenState extends State<AlarmScreen> {
  late double _dragValue;
  late AlarmEntity _alarm;
  final int alarmItemId;

  _AlarmScreenState(this.alarmItemId);

  @override
  void initState() {
    super.initState();
    _loadAlarm();
    _dragValue = 0.0;
  }

  Future<void> _loadAlarm() async {
    _alarm = (await SqfliteService().getAlarm(alarmItemId))!;
    setState(() {});
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // center vertically
                children: [
                  Text(
                    _formatDateTime(DateTime.now()),
                    style: TextStyle(fontSize: 90, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    getBody(_alarm.label, _alarm.time),
                    style: TextStyle(fontSize: 40, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const Text('Slide this button to left or right.'),
                  const SizedBox(height: 64.0),
                  HorizontalSlidableButton(
                    height: MediaQuery.of(context).size.height / 10,
                    width: MediaQuery.of(context).size.width / 1.25,
                    buttonWidth: MediaQuery.of(context).size.width / 5,
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.5),
                    buttonColor: Theme.of(context).primaryColor,
                    dismissible: true,
                    label: const Center(child: Text('Slide Me')),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Stop',
                              style: TextStyle(
                                  fontSize: 20.0, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                    onChanged: (position) {
                      setState(() {
                        if (position == SlidableButtonPosition.end) {
                          AlarmManagerApi.stopAlarm(alarmItemId);
                          Navigator.of(context).pop();
                        }
                      });
                    },
                  ),
                  SizedBox(height: 20), // add a bit of spacing
                  ElevatedButton(
                    onPressed: () {
                      AlarmManagerApi.snoozeAlarm(alarmItemId);
                      Navigator.of(context).pop();
                    },
                    child: Text('Snooze'),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.grey, // background
                      onPrimary: Colors.white, // foreground
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String getBody(String label, DateTime time) {
    var body = label.isEmpty
        ? DateTimeUtils.formatDateTimeAs24HoursFormat(time)
        : '${DateTimeUtils.formatDateTimeAs24HoursFormat(time)} - $label';

    return body;
  }

  @override
  void dispose() {
    // didReceiveLocalNotificationStream.close();
    // selectNotificationStream.close();
    super.dispose();
  }
}
