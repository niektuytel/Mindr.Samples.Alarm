package com.mindr.alarm.models

data class AlarmEntity(
        val id: Int,
        val time: String,
        val label: String,
        val scheduledDays: String,
        val isEnabled: Int,
        val sound: String,
        val vibrationChecked: Int,
        val syncWithMindr: Int
)
