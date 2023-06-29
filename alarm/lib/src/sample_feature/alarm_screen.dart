import 'package:flutter/material.dart';

class AlarmScreen extends StatefulWidget {
  final String? payload;

  const AlarmScreen({Key? key, this.payload}) : super(key: key);

  @override
  _AlarmScreenState createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alarm'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Alarm Fired!',
              style: TextStyle(fontSize: 30),
            ),
            Text(
              'Payload: ${widget.payload ?? 'No payload'}',
              style: TextStyle(fontSize: 20),
            ),
            // Here, you can also add 'Snooze' and 'Dismiss' buttons, and handle their functionality.
          ],
        ),
      ),
    );
  }
}
