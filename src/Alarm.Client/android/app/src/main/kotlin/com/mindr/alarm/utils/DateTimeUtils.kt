package com.mindr.alarm.utils
import com.mindr.alarm.models.AlarmEntity
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class DateTimeUtils {
    companion object {
        fun getBody(item: AlarmEntity): String {
            // Convert ISO 8601 string to Date
            val sdf = SimpleDateFormat("EEE h:mm a", Locale.US)
            val date = sdf.format(item.time.time)

            return if (item.label.isNotEmpty()) {
                "$date - ${item.label}"
            } else {
                date
            }
        }

        fun setNextItemTime(item: AlarmEntity, checkOnDateTime: Calendar): AlarmEntity {
            val nextTime = Calendar.getInstance()
            nextTime.set(checkOnDateTime.get(Calendar.YEAR),
                    checkOnDateTime.get(Calendar.MONTH),
                    checkOnDateTime.get(Calendar.DAY_OF_MONTH),
                    item.time.get(Calendar.HOUR_OF_DAY),
                    item.time.get(Calendar.MINUTE))

            if (item.isEnabled == 0) {
                return item
            } else if (item.scheduledDays.isEmpty()) {
                if (nextTime.before(checkOnDateTime)) {
                    nextTime.add(Calendar.DAY_OF_MONTH, 1)
                }
                item.time = nextTime
                println("Next time: ${item.time.time}")
                return item
            }

            // Assuming `scheduledDays` is a comma-separated list of integers as strings
            val scheduledDays = item.scheduledDays.split(",").map { it.trim().toInt() }.sorted()
            val dayOfWeek = nextTime.get(Calendar.DAY_OF_WEEK)
            val nextDay = scheduledDays.firstOrNull { it > dayOfWeek } ?: scheduledDays.first()

            val daysToAdd = if (nextDay > dayOfWeek) {
                nextDay - dayOfWeek
            } else {
                7 - dayOfWeek + nextDay
            }

            if (scheduledDays.contains(dayOfWeek) && nextTime.after(checkOnDateTime)) {
                item.time = nextTime
                println("Next time: ${item.time.time} [nextDay: $nextDay, dayOfWeek: $dayOfWeek daysToAdd: $daysToAdd]")
                return item
            }

            nextTime.add(Calendar.DAY_OF_MONTH, daysToAdd)
            item.time = nextTime
            println("Next time: ${item.time.time} [nextDay: $nextDay, dayOfWeek: $dayOfWeek daysToAdd: $daysToAdd]")
            return item
        }
    }
}
