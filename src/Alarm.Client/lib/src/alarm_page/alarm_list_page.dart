import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:intl/intl.dart';
import 'package:client/src/alarm_page/alarm_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../../main.dart';
import '../mindr_page/mindr_view.dart';
import 'alarm_notifications.dart';
import '../services/shared_preferences_service.dart';
import '../services/sqflite_service.dart';
import '../models/alarm_item_view.dart';

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

  @override
  void initState() {
    super.initState();

    // // Foreground task
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   // TODO: maybe later use this on specific versions of android
    //   await _requestPermissionForAndroid();

    //   // _initForegroundTask();

    //   // // You can get the previous ReceivePort without restarting the service.
    //   // if (await FlutterForegroundTask.isRunningService) {
    //   //   final newReceivePort = FlutterForegroundTask.receivePort;
    //   //   _registerReceivePort(newReceivePort);
    //   // }
    // });

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
    AlarmReceiver.init(context);
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
          TimeOfDay? selectedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (selectedTime != null) {
            AlarmItemView newAlarm = AlarmItemView(
              0, // Change to appropriate ID based on your requirements
              DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
                selectedTime.hour,
                selectedTime.minute,
              ),
              [], // Default days
              true,
              '', // Default sound
              true, // Default vibrationChecked
              true, // Default syncWithMindr
            );
            setState(() {
              widget.items.add(newAlarm);
            });
            SqfliteService()
                .insertAlarm(newAlarm); // Insert new alarm into the database
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
                item.time = DateTime(
                  item.time.year,
                  item.time.month,
                  item.time.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
              });
              await SqfliteService()
                  .updateAlarm(item); // update in the database
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
          onChanged: (newValue) {
            setState(() => item.enabled = newValue);
            SqfliteService().updateAlarm(item); // update in the database
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
          _buildSwitchRow(item.vibrationChecked, 'Vibration', (value) {
            setState(() {
              item.vibrationChecked = value!;
              SqfliteService().updateAlarm(item); // update in the database
            });
          }),
          _buildSwitchRow(item.syncWithMindr, 'Bind with Mindr', (value) {
            setState(() {
              item.syncWithMindr = value!;
              SqfliteService().updateAlarm(item); // update in the database
            });
          }),
        ],
      ),
    );
  }

  List<Widget> _buildDaySelectors(AlarmItemView item, List<String> dayNames) {
    return List<Widget>.generate(7, (index) {
      bool isScheduled = item.scheduledDays.contains(index + 1);
      return GestureDetector(
        onTap: () {
          setState(() {
            if (isScheduled) {
              item.scheduledDays.remove(index + 1);
            } else {
              item.scheduledDays.add(index + 1);
            }
            SqfliteService().updateAlarm(item); // update in the database
          });
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
    super.dispose();
  }

  String getFormattedScheduledDays(List<int> scheduledDays) {
    scheduledDays.sort();
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    List<String> selectedDays = [];

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
