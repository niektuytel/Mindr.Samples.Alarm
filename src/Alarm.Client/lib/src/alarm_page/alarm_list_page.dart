import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../mindr_page/mindr_view.dart';
import '../services/alarm_service.dart';
import '../services/alarm_handler.dart';
import '../services/sqflite_service.dart';
import '../models/alarm_item_view.dart';
import 'alarm_screen.dart';

class AlarmListPage extends StatefulWidget {
  static const routeName = '/';

  AlarmListPage({Key? key, List<AlarmItemView>? items})
      : _items = items,
        super(key: key);

  List<AlarmItemView>? _items = [];

  List<AlarmItemView> get items => _items ?? [];
  set items(List<AlarmItemView> value) {
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
    super.initState();

    // Foreground task
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _requestPermissionForAndroid(); // Needed for Redmi 8

      // _initForegroundTask();

      // // You can get the previous ReceivePort without restarting the service.
      // if (await FlutterForegroundTask.isRunningService) {
      //   final newReceivePort = FlutterForegroundTask.receivePort;
      //   _registerReceivePort(newReceivePort);
      // }
    });

    SqfliteService().getAlarms().then((alarms) {
      setState(() {
        widget.items = alarms;
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
              _buildListItem,
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

            AlarmItemView newAlarm = AlarmItemView(
              0, // Change to appropriate ID based on your requirements
              time,
              [], // Default days
              true,
              '', // Default sound
              true, // Default vibrationChecked
              true, // Default syncWithMindr
            );
            setState(() {
              widget.items.add(newAlarm);
            });

            await AlarmService.insertAlarm(newAlarm);
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
          Navigator.restorablePushNamed(context, MindrView.routeName);
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

  Widget _buildListItem(BuildContext context, int index) {
    final item = widget.items[index];
    return Card(
      margin: const EdgeInsets.all(8.0),
      color: const Color.fromARGB(255, 53, 53, 53),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ExpansionTile(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        title: GestureDetector(
          onTap: () async {
            TimeOfDay? selectedTime = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(item.time),
            );
            if (selectedTime != null) {
              setState(() {
                var time = DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                item.time = time;
              });
              await AlarmService.updateAlarm(item, true);
            }
          },
          child: Text(
            DateFormat('h:mm a').format(item.time),
            style: TextStyle(
              fontWeight: item.enabled ? FontWeight.bold : FontWeight.normal,
              fontSize: 50,
              color: item.enabled
                  ? Colors.white
                  : const Color.fromARGB(255, 155, 155, 155),
            ),
          ),
        ),
        subtitle: _buildSubtitle(item),
        trailing: Icon(
          item.isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
          color: Colors.white,
        ),
        onExpansionChanged: (newState) {
          setState(() => item.isExpanded = newState);
        },
        children: [_buildExpansionTileChildren(item)],
      ),
    );
  }

  Widget _buildSubtitle(AlarmItemView item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(getFormattedScheduledDays(item.scheduledDays),
            style: const TextStyle(fontSize: 16, color: Colors.white)),
        Switch(
          value: item.enabled,
          onChanged: (newValue) async {
            setState(() => item.enabled = newValue);

            // // Cancel the previous timer
            // _daySelectionTimer?.cancel();
            // // Start a new one
            // _daySelectionTimer = Timer(Duration(seconds: 3), () async {
            //   // When the timer fires, update the database
            await AlarmService.updateAlarm(item, true);
            // });
          },
          activeColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildExpansionTileChildren(AlarmItemView item) {
    const dayNames = ["S", "M", "T", "W", "T", "F", "S"];
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [..._buildDaySelectors(item, dayNames)]),
          _buildLabelInput(item),
          _buildSwitchRow(item.vibrationChecked, 'Vibration', (value) async {
            setState(() => item.vibrationChecked = value!);
            await AlarmService.updateAlarm(item, false);
          }),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    await AlarmService.deleteAlarm(item.id);
                    setState(() {
                      widget.items.remove(item);
                    });
                  },
                  icon: Icon(Icons.delete, color: Colors.white),
                  label: Text(
                    'Delete',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    setState(() {
                      item.syncWithMindr = !item.syncWithMindr;
                      SqfliteService()
                          .updateAlarm(item); // update in the database
                    });
                  },
                  icon: Icon(item.syncWithMindr ? Icons.link : Icons.link_off,
                      color: Colors.white),
                  label: Text(
                    'Bind with Mindr',
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

  Widget _buildLabelInput(AlarmItemView item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: item.label,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          labelText: 'Label',
          labelStyle: TextStyle(color: Colors.white),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
        ),
        onChanged: (value) async {
          item.label = value;
          await AlarmService.updateAlarm(item, false);
        },
      ),
    );
  }

  List<Widget> _buildDaySelectors(AlarmItemView item, List<String> dayNames) {
    return List<Widget>.generate(7, (index) {
      bool isScheduled = item.scheduledDays.contains(index + 1);
      return GestureDetector(
        onTap: () async {
          if (isScheduled) {
            item.scheduledDays.remove(index + 1);
          } else {
            item.scheduledDays.add(index + 1);
          }
          // Now update the database
          await AlarmService.updateAlarm(item, true);
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

  Widget _buildSwitchRow(bool value, String text, Function(bool?) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text, style: const TextStyle(fontSize: 16, color: Colors.white)),
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: const Color.fromARGB(255, 106, 200, 255),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _daySelectionTimer
        ?.cancel(); // make sure to dispose the timer when not needed
    _vibrationChangeTimer
        ?.cancel(); // make sure to dispose the timer when not needed
    super.dispose();
  }

  String getFormattedScheduledDays(List<int> scheduledDays) {
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    List<String> selectedDays = [];

    if (scheduledDays.length == 7) {
      return 'Daily';
    }

    scheduledDays.sort();
    for (int dayIndex in scheduledDays) {
      if (dayIndex >= 1 && dayIndex <= 7) {
        selectedDays.add(dayNames[dayIndex - 1]);
      }
    }

    return selectedDays.join(', ');
  }
}

Future<void> _requestPermissionForAndroid() async {
  if (!Platform.isAndroid) {
    return;
  }

  // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
  // onNotificationPressed function to be called.
  //
  // When the notification is pressed while permission is denied,
  // the onNotificationPressed function is not called and the app opens.
  //
  // If you do not use the onNotificationPressed or launchApp function,
  // you do not need to write this code.
  if (!await FlutterForegroundTask.canDrawOverlays) {
    // This function requires `android.permission.SYSTEM_ALERT_WINDOW` permission.
    await FlutterForegroundTask.openSystemAlertWindowSettings();
  }

  // Android 12 or higher, there are restrictions on starting a foreground service.
  //
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
