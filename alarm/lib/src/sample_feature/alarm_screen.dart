import 'package:flutter/material.dart';

class AlarmScreen extends StatefulWidget {
  final String? payload;

  const AlarmScreen({Key? key, this.payload}) : super(key: key);

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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Center(
              child: Text(
                _formatDateTime(DateTime.now()),
                style: TextStyle(fontSize: 30, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Text(
            'Alarm',
            style: TextStyle(fontSize: 20, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4.0,
              thumbColor: Colors.blue,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 20.0),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 30.0),
            ),
            child: Slider(
              value: _dragValue,
              onChanged: (newValue) {
                setState(() {
                  _dragValue = newValue;
                });
              },
              onChangeEnd: _onDragEnd,
              min: -1.0,
              max: 1.0,
              divisions: 2,
              label: _dragValue < 0 ? 'Snooze' : 'Stop',
              activeColor: _dragValue < 0 ? Colors.blue : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
