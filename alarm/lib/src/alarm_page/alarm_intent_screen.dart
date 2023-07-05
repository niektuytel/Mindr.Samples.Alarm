import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slidable_button/slidable_button.dart';

import 'alarm_notifications.dart';
import '../db_helper.dart';

// class HomePage extends StatefulWidget {
//   const HomePage(
//     this.notificationAppLaunchDetails, {
//     Key? key,
//   }) : super(key: key);

//   static const String routeName = '/';

//   final NotificationAppLaunchDetails? notificationAppLaunchDetails;

//   bool get didNotificationLaunchApp =>
//       notificationAppLaunchDetails?.didNotificationLaunchApp ?? false;

//   @override
//   _HomePageState createState() => _HomePageState();
// }

class AlarmScreen extends StatefulWidget {
  final String? payload;

  const AlarmScreen({Key? key, this.payload}) : super(key: key);
  static const String routeName = '/alarmScreen';

  @override
  _AlarmScreenState createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  late double _dragValue;

  @override
  void initState() {
    super.initState();
    _dragValue = 0.0;
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  void _onDragEnd(double details) {
    if (_dragValue <= -0.5) {
      print('Snooze function triggered');
    } else if (_dragValue >= 0.5) {
      print('Stop alarm function triggered');
    }
    _dragValue = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> payload =
        new Map<String, dynamic>(); // jsonDecode(widget.payload!);
    int alarmId = 123;
    // payload['alarmId'];

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
                    'Alarm',
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
                        // SharedPreferences prefs =
                        //     SharedPreferences.getInstance()..getInstance().then((value) => null);

                        if (position == SlidableButtonPosition.end) {
                          Navigator.pop(context);
                        }
                        //     position == SlidableButtonPosition.start) {
                        //   // Cancel notifications.
                        //   await AlarmReceiver.showMissedNotification(alarmId);

                        //   // Delete the alarm from the database.
                        //   DBHelper dbHelper = DBHelper();
                        //   await dbHelper.delete(alarmId);

                        //   // Remove payload from shared preferences.
                        //   await prefs.remove('pendingPayload');
                        // }
                      });
                    },
                  ),
                  SizedBox(height: 20), // add a bit of spacing
                  ElevatedButton(
                    onPressed: () {
                      print("Snooze button pressed");
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

  @override
  void dispose() {
    // didReceiveLocalNotificationStream.close();
    // selectNotificationStream.close();
    super.dispose();
  }
}
