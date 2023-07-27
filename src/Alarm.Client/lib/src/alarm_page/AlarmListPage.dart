import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:mindr.alarm/src/alarm_page/widgets/AlarmCardWidget.dart';
import 'package:mindr.alarm/src/services/alarmManagerApi.dart';
import 'package:provider/provider.dart';
import '../models/AlarmEntityView.dart';
import '../services/sqflite_service.dart';

class AlarmListPage extends StatefulWidget {
  static const routeName = '/';

  AlarmListPage({Key? key, List<AlarmEntityView>? items})
      : _items = items,
        super(key: key);

  List<AlarmEntityView>? _items = [];

  List<AlarmEntityView> get items => _items ?? [];
  set items(List<AlarmEntityView> value) {
    _items = value;
  }

  @override
  State<StatefulWidget> createState() => _AlarmListPageState();
}

class _AlarmListPageState extends State<AlarmListPage> {
  late final ScrollController _scrollController;
  Color _appBarColor = Colors.transparent;
  int alarmId = 0;
  Timer? _daySelectionTimer;
  Timer? _vibrationChangeTimer;

  @override
  void initState() {
    // loadAllNotifications;
    super.initState();

    // // Foreground task
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   await _requestPermissionForAndroid(); // Needed for Redmi 8
    // });

    SqfliteService().getAlarms().then((alarms) {
      setState(() {
        widget.items =
            alarms.map((e) => AlarmEntityView.fromAlarmEntity(e)).toList();
      });
    });
    _scrollController = ScrollController()..addListener(_scrollListener);
  }

  void _scrollListener() {
    final color = _scrollController.position.pixels > 10
        ? const Color.fromARGB(255, 119, 119, 119)
        : Colors.transparent;
    setState(() => _appBarColor = color);
  }

  @override
  Widget build(BuildContext context) {
    const dayNames = ["S", "M", "T", "W", "T", "F", "S"];

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return AlarmCardWidget(widget.items[index], widget.items);
              },
              childCount: widget.items.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          DateTime now = DateTime.now();
          DateTime after15Min = now.add(Duration(minutes: 15));
          TimeOfDay initialTime =
              TimeOfDay(hour: after15Min.hour, minute: after15Min.minute);

          TimeOfDay? selectedTime = await showTimePicker(
            context: context,
            initialTime: initialTime,
          );

          if (selectedTime != null) {
            DateTime time = DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
              selectedTime.hour,
              selectedTime.minute,
            );
            var newAlarm = AlarmEntityView(
              0, // Change to appropriate ID based on your requirements
              time,
              [], // Default days
              true,
              '', // Default sound
              true, // Default vibrationChecked
              false, // Default syncWithMindr
            );
            setState(() {
              widget.items.add(newAlarm);
            });

            var alarm = newAlarm.toAlarmEntity();
            await AlarmManagerApi.insertAlarm(alarm);
          }
        },
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: _appBarColor,
      title: const Text('Alarm'),
      actions: [_buildPopupMenu()],
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<int>(
      color: const Color.fromARGB(255, 90, 90, 90),
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (value) {
        if (value == 0) {
          // Navigator.restorablePushNamed(context, MindrView.routeName);
        } else if (value == 1) {
          //TODO: Navigator.restorablePushNamed(context, FeedbackView.routeName);
        } else if (value == 2) {
          //TODO: Navigator.restorablePushNamed(context, SettingsView.routeName);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
            value: 0,
            child: Text('Mindr', style: TextStyle(color: Colors.white))),
        PopupMenuItem(
            value: 1,
            child:
                Text('Send feedback', style: TextStyle(color: Colors.white))),
        PopupMenuItem(
            value: 2,
            child: Text('Settings', style: TextStyle(color: Colors.white))),
      ],
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _daySelectionTimer?.cancel();
    _vibrationChangeTimer?.cancel();
    super.dispose();
  }
}

Future<void> _requestPermissionForAndroid() async {
  if (!Platform.isAndroid) {
    return;
  }

  // // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
  // // onNotificationPressed function to be called.
  // //
  // // When the notification is pressed while permission is denied,
  // // the onNotificationPressed function is not called and the app opens.
  // //
  // // If you do not use the onNotificationPressed or launchApp function,
  // // you do not need to write this code.
  // if (!await FlutterForegroundTask.canDrawOverlays) {
  //   // This function requires `android.permission.SYSTEM_ALERT_WINDOW` permission.
  //   await FlutterForegroundTask.openSystemAlertWindowSettings();
  // }

  // Android 12 or higher, there are restrictions on starting a foreground service.
  // To restart the service on device reboot or unexpected problem, you need to allow below permission.
  if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
    // This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
    await FlutterForegroundTask.requestIgnoreBatteryOptimization();
  }

  // Android 13 and higher, you need to allow notification permission to expose foreground service notification.
  final NotificationPermission notificationPermissionStatus =
      await FlutterForegroundTask.checkNotificationPermission();
  if (notificationPermissionStatus != NotificationPermission.granted) {
    await FlutterForegroundTask.requestNotificationPermission();
  }
}

  // loadAllNotifications() {
  //   NotificationApi.showWeeklyScheduledNotification(
  //       title: '🏆 New Deals Available 🏆',
  //       body: '✨ Don\'t miss your opportunity to win BIG 💰💰',
  //       scheduledDate: DateTime.now().add(const Duration(seconds: 12)));
  //   NotificationApi.init();
  //   listenNotifications();
  // }

  // // Listen to Notifications
  // void listenNotifications() =>
  //     NotificationApi.onNotifications.stream.listen(onClickedNotification);

  // void onClickedNotification(NotificationResponse? payload) =>
  //     Navigator.of(context)
  //         .push(MaterialPageRoute(builder: (context) => AlarmScreen(1)));
  // // end
