package com.mindr.alarm.models

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

data class AlarmEntity(
        val id: Int,
        var time: Date,
        val label: String,
        val scheduledDays: String,
        val isEnabled: Int,
        val sound: String,
        val vibrationChecked: Int,
        val syncWithMindr: Int
) {
    companion object {
        val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)

        fun fromMap(map: Map<String, Any>): AlarmEntity {
            return AlarmEntity(
                    id = (map["id"] as Double).toInt(),
                    time = dateFormat.parse(map["time"] as String) ?: Date(),
                    label = map["label"] as String,
                    scheduledDays = map["scheduledDays"] as String,
                    isEnabled = (map["isEnabled"] as Double).toInt(),
                    sound = map["sound"] as String,
                    vibrationChecked = (map["vibrationChecked"] as Double).toInt(),
                    syncWithMindr = (map["syncWithMindr"] as Double).toInt()
            )
        }

    }

    fun toMap(): Map<String, Any> {
        return mapOf(
                "id" to id,
                "time" to dateFormat.format(time),
                "label" to label,
                "scheduledDays" to scheduledDays,
                "isEnabled" to isEnabled,
                "sound" to sound,
                "vibrationChecked" to vibrationChecked,
                "syncWithMindr" to syncWithMindr
        )
    }
}

