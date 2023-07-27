import 'package:intl/intl.dart';

import '../models/AlarmEntity.dart';
import '../models/AlarmEntityView.dart';

class DateTimeUtils {
  static String formatDateTimeAs24HoursFormat(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  static String formatDateTimeAsDay(DateTime dateTime) {
    return DateFormat('EEE h:mm a').format(dateTime);
  }

  static String formatDateTimeAsDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);
  }

  static Future<AlarmEntity> setNextItemTime(AlarmEntity item) async {
    // item.time = DateTime.now().add(Duration(hours: 2, seconds: 10));
    // print('Next time: ${item.time}');
    // return item;
    var scheduledDays = item.scheduledDays.isEmpty
        ? []
        : item.scheduledDays
            .split(',')
            .map((item) => int.parse(item.toString()))
            .toList();

    var nextTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      item.time.hour,
      item.time.minute,
    );

    if (!item.isEnabled) {
      return item;
    } else if (item.scheduledDays.isEmpty) {
      if (nextTime.isBefore(DateTime.now())) {
        nextTime = nextTime.add(Duration(days: 1));
      }

      item.time = nextTime;
      print('Next time: ${item.time}');
      return item;
    }

    scheduledDays.sort();
    var dayOfWeek = nextTime.weekday + 1;
    var nextDay = scheduledDays.firstWhere((element) => element > dayOfWeek,
        orElse: () => scheduledDays.first);

    // calculate the number of days to add
    int daysToAdd =
        (nextDay > dayOfWeek ? nextDay - dayOfWeek : 7 - dayOfWeek + nextDay);

    // if the next day is today, add 7 days if the time is before now
    if (scheduledDays.contains(dayOfWeek) && nextTime.isAfter(DateTime.now())) {
      item.time = nextTime;
      print(
          'Next time: ${item.time} [nextDay: $nextDay, dayOfWeek: $dayOfWeek daysToAdd: $daysToAdd]');
      return item;
    }

    item.time = nextTime.add(Duration(days: daysToAdd));
    print(
        'Next time: ${item.time} [nextDay: $nextDay, dayOfWeek: $dayOfWeek daysToAdd: $daysToAdd]');
    return item;
  }
}
