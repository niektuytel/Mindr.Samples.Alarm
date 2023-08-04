import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:mindr.alarm/src/services/alarmManagerApi.dart';
import '../models/alarmEntity.dart';
import '../services/alarmNotificationApi.dart';
import '../services/shared_preferences_service.dart';
import '../services/sqflite_service.dart';
import '../utils/datetimeUtils.dart';
// import 'alarm_screen.dart';
import 'package:http/http.dart' as http;

class AlarmListPage extends StatefulWidget {
  static const routeName = '/';

  AlarmListPage({Key? key, List<AlarmEntity>? items})
      : _items = items,
        super(key: key);

  List<AlarmEntity>? _items = [];

  List<AlarmEntity> get items => _items ?? [];
  set items(List<AlarmEntity> value) {
    _items = value;
  }

  @override
  State<StatefulWidget> createState() => _AlarmListPageState();
}

class _AlarmListPageState extends State<AlarmListPage>
    with SingleTickerProviderStateMixin {
  SyncStatus syncStatus = SyncStatus.synced; // Assume synced initially

  late final ScrollController _scrollController;
  late AnimationController _syncIconController;

  Color _appBarColor = Colors.transparent;
  int alarmId = 0;
  Timer? _daySelectionTimer;
  Timer? _vibrationChangeTimer;

  Future<void> syncWithServer(String userId) async {
    setState(() {
      syncStatus = SyncStatus.syncing;
    });

    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      final url =
          Uri.parse('https://alarmtestapi.azurewebsites.net/api/UserDevices');
      final data = {"user_id": userId, "device_token": fcmToken};

      print('data: $data');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 204) {
        setState(() {
          syncStatus = SyncStatus.synced;
        });
      } else {
        print(' status: ${response.statusCode} response: ${response.body}');
        // Handle unsuccessful HTTP request (status code other than 200)
        setState(() {
          syncStatus = SyncStatus.notSynced;
        });
      }
    } catch (error) {
      print(error);
      // Handle any exceptions that might occur during the HTTP request
      setState(() {
        syncStatus = SyncStatus.notSynced;
      });
    }
  }

  @override
  void initState() {
    // loadAllNotifications;
    super.initState();

    _syncIconController = AnimationController(
      vsync: this,
      duration: const Duration(
          seconds: 2), // This is the duration for one complete revolution.
    )..repeat(); // This will keep the animation ongoing.

    // // Foreground task
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   await _requestPermissionForAndroid(); // Needed for Redmi 8
    // });

    SqfliteService().getAlarms().then((alarms) {
      setState(() {
        widget.items = alarms;
      });
    });
    _scrollController = ScrollController()..addListener(_scrollListener);
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

            AlarmEntity newAlarm = AlarmEntity(time);
            setState(() {
              widget.items.add(newAlarm);
            });

            // if (await FlutterForegroundTask.isIgnoringBatteryOptimizations ==
            //     false) {
            // var permissions = await FlutterForegroundTask.checkNotificationPermission();
            // await FlutterForegroundTask.requestIgnoreBatteryOptimization();
            // }

            await AlarmManagerApi.insertAlarm(newAlarm);
          }
        },
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return FutureBuilder<String?>(
      future: SharedPreferencesService.getUserId(),
      builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data != null) {
            return SliverAppBar(
              pinned: true,
              backgroundColor: _appBarColor,
              title: const Text('Alarm'),
              actions: [
                IconButton(
                  icon: _buildSyncIcon(),
                  onPressed: () async => await syncWithServer(snapshot.data!),
                ),
                _buildPopupMenu(),
              ],
            );
          } else {
            return SliverAppBar(
              pinned: true,
              backgroundColor: _appBarColor,
              title: const Text('Alarm'),
              actions: [
                IconButton(
                  icon: Icon(
                      Icons.account_circle), // replace with your preferred icon
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("Login with mindr"),
                          content: Text(
                              "Give mindr the ability to manage your alarms"),
                          actions: <Widget>[
                            TextButton(
                              child: Text("Cancel"),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: Text("OK"),
                              onPressed: () async {
                                // TODO: Redirect to login page or open login dialog and return userid back
                                var userId =
                                    '79c0ff3d-32aa-445b-b9e5-330799cb03c1'; // test@test.com
                                // var userId = '410786db-7682-45e5-9099-686c21626d9c'; // tuytelniek@gmail.com (3th parties, gmail/google login)

                                var success =
                                    await SharedPreferencesService.setUserId(
                                        userId);
                                Navigator.of(context).pop();
                                if (success) setState(() {});
                                await syncWithServer(userId);
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                _buildPopupMenu(),
              ],
            );
          }
        } else {
          // while data is loading:
          return SliverAppBar(
            pinned: true,
            backgroundColor: _appBarColor,
            title: const Text('Alarm'),
            actions: [
              IconButton(
                icon: CircularProgressIndicator(), // show loading icon
                onPressed: null,
              ),
              _buildPopupMenu(),
            ],
          );
        }
      },
    );
  }

  Widget _buildSyncIcon() {
    if (syncStatus == SyncStatus.syncing) {
      return AnimatedBuilder(
        animation: _syncIconController,
        builder: (_, __) {
          return Transform.rotate(
            angle: -_syncIconController.value * 2 * pi,
            child: Icon(Icons.sync, color: Colors.white),
          );
        },
      );
    } else if (syncStatus == SyncStatus.notSynced) {
      return Icon(Icons.sync_problem, color: Colors.red);
    } else {
      return Icon(Icons.sync, color: Colors.white);
    }
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
              await AlarmManagerApi.updateAlarm(item, true);
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

  Widget _buildSubtitle(AlarmEntity item) {
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
            await AlarmManagerApi.updateAlarm(item, true);
            // });
          },
          activeColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildExpansionTileChildren(AlarmEntity item) {
    const dayNames = ["S", "M", "T", "W", "T", "F", "S"];
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [..._buildDaySelectors(item, dayNames)]),
          _buildLabelInput(item),
          _buildSpecificTimeText(item),
          _buildSwitchRow(item.vibrationChecked, 'Vibration', (value) async {
            setState(() => item.vibrationChecked = value!);
            await AlarmManagerApi.updateAlarm(item, false);
          }),
          _buildSwitchRow(item.syncWithMindr, 'Connected to mindr',
              (value) async {
            setState(() => item.syncWithMindr = value!);
            await AlarmManagerApi.updateAlarm(item, false);
          }),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    await AlarmManagerApi.deleteAlarm(item.id);
                    widget.items.remove(item);
                    setState(() {});
                  },
                  icon: Icon(Icons.delete, color: Colors.white),
                  label: Text(
                    'Delete',
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

  Widget _buildLabelInput(AlarmEntity item) {
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
          await AlarmManagerApi.updateAlarm(item, false);
        },
      ),
    );
  }

  Widget _buildSpecificTimeText(AlarmEntity item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Next',
          labelStyle: TextStyle(color: Colors.white),
          border: InputBorder.none,
        ),
        child: Text(
          DateTimeUtils.formatDateTimeAsDate(item.time),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSpecificTimeInput(AlarmEntity item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            item.label, // Display the label text from the item
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDaySelectors(AlarmEntity item, List<String> dayNames) {
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
          await AlarmManagerApi.updateAlarm(item, true);
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
    _syncIconController.dispose();
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

enum SyncStatus {
  synced, // Successfully synced with the server
  syncing, // Currently syncing with the server
  notSynced, // Failed to sync with the server or haven't synced yet
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
