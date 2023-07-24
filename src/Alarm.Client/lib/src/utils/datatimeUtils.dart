import 'package:intl/intl.dart';

import '../models/alarm_item_view.dart';

class DateTimeUtils {
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('EEE h:mm a').format(dateTime);
  }

  static Future<AlarmItemView> setNextItemTime(AlarmItemView item) async {
    var nextTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      item.time.hour,
      item.time.minute,
    );

    if (!item.enabled) {
      return item;
    } else if (item.scheduledDays.isEmpty) {
      if (nextTime.isBefore(DateTime.now())) {
        nextTime = nextTime.add(Duration(days: 1));
      }

      item.time = nextTime;
      print('Next time: ${item.time}');
      return item;
    }

    item.scheduledDays.sort();
    var dayOfWeek = nextTime.weekday + 1;
    var nextDay = item.scheduledDays.firstWhere(
        (element) => element > dayOfWeek,
        orElse: () => item.scheduledDays.first);

    // calculate the number of days to add
    int daysToAdd =
        (nextDay > dayOfWeek ? nextDay - dayOfWeek : 7 - dayOfWeek + nextDay);

    // if the next day is today, add 7 days if the time is before now
    if (item.scheduledDays.contains(dayOfWeek) &&
        nextTime.isAfter(DateTime.now())) {
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
