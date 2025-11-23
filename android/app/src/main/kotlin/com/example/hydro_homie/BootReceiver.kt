package com.example.hydro_homie

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log
import org.json.JSONObject
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            try {
                val prefs: SharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val key = "flutter.app_settings_v1"
                val raw = prefs.getString(key, null)
                if (raw != null) {
                    val map = JSONObject(raw)
                    if (map.has("reminderIntervalMinutes") && !map.isNull("reminderIntervalMinutes")) {
                        val minutes = map.getInt("reminderIntervalMinutes")
                        if (minutes > 0) {
                            val useWork = map.optBoolean("use_work_manager", false)
                            val useInexact = map.optBoolean("use_inexact", false)
                            if (useWork) {
                                scheduleWorkManager(context, minutes)
                            } else if (useInexact) {
                                scheduleInexactRepeating(context, minutes)
                            } else {
                                scheduleAlarm(context, minutes)
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                Log.w("BootReceiver", "failed to reschedule reminders: ${e.message}")
            }
        }
    }

    private fun scheduleAlarm(context: Context, minutes: Int) {
        try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                val channelId = "hydration_reminders"
                val chan = android.app.NotificationChannel(channelId, "Hydration Reminders", android.app.NotificationManager.IMPORTANCE_DEFAULT)
                notificationManager.createNotificationChannel(chan)
            }
        } catch (_: Exception) {
        }
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, ReminderReceiver::class.java)
        intent.action = "com.example.hydro_homie.ACTION_REMIND"
        val pending = PendingIntent.getBroadcast(context, 1001, intent, if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT else PendingIntent.FLAG_UPDATE_CURRENT)
        val interval = minutes * 60 * 1000L
        val triggerAt = System.currentTimeMillis() + interval
        alarmManager.setInexactRepeating(AlarmManager.RTC_WAKEUP, triggerAt, interval, pending)
    }

    private fun scheduleInexactRepeating(context: Context, minutes: Int) {
        try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                val channelId = "hydration_reminders"
                val chan = android.app.NotificationChannel(channelId, "Hydration Reminders", android.app.NotificationManager.IMPORTANCE_DEFAULT)
                notificationManager.createNotificationChannel(chan)
            }
        } catch (_: Exception) {
        }
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, ReminderReceiver::class.java)
        intent.action = "com.example.hydro_homie.ACTION_REMIND"
        val pending = PendingIntent.getBroadcast(context, 1001, intent, if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT else PendingIntent.FLAG_UPDATE_CURRENT)
        val interval = minutes * 60 * 1000L
        alarmManager.setInexactRepeating(AlarmManager.RTC_WAKEUP, System.currentTimeMillis() + interval, interval, pending)
    }

    private fun scheduleWorkManager(context: Context, minutes: Int) {
        val period = if (minutes < 15) 15L else minutes.toLong()
        val workRequest = PeriodicWorkRequestBuilder<ReminderWorker>(period, TimeUnit.MINUTES).build()
        WorkManager.getInstance(context).enqueueUniquePeriodicWork("hydration_reminder", ExistingPeriodicWorkPolicy.REPLACE, workRequest)
    }
}
