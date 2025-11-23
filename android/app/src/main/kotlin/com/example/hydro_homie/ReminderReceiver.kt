package com.example.hydro_homie

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.app.NotificationManager
import androidx.core.app.NotificationCompat
import android.app.PendingIntent
import android.os.Build
import android.content.SharedPreferences
import android.app.AlarmManager
import org.json.JSONObject
import android.app.NotificationChannel
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.i("ReminderReceiver", "onReceive: action=${intent.action}")
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelId = "hydration_reminders"
        val title = "Time to drink"
        val body = "Take a sip to stay on track"
        val launchIntent = Intent(context, MainActivity::class.java)
        launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        val pending = PendingIntent.getActivity(context, 0, launchIntent, if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT else PendingIntent.FLAG_UPDATE_CURRENT)
        val builder = NotificationCompat.Builder(context, channelId)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pending)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val chan = NotificationChannel(channelId, "Hydration Reminders", NotificationManager.IMPORTANCE_DEFAULT)
            notificationManager.createNotificationChannel(chan)
        }

        Log.i("ReminderReceiver", "showing notification id=1001 channel=$channelId title=$title")

        notificationManager.notify(1001, builder.build())

        // Send callback to Dart via MethodChannel
        try {
            val notificationData = mapOf(
                "id" to 1001,
                "title" to title,
                "body" to body,
                "timestamp" to System.currentTimeMillis()
            )
            MainActivity.methodChannel?.invokeMethod("onNativeNotification", notificationData)
        } catch (e: Exception) {
            Log.e("ReminderReceiver", "Error sending callback: ${e.message}")
        }

        try {
            val prefs: SharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val key = "flutter.app_settings_v1"
            val raw = prefs.getString(key, null)
            val lastKey = "flutter.last_native_notification_v1"
            val now = System.currentTimeMillis()
            val last = JSONObject()
            last.put("id", 1001)
            last.put("title", title)
            last.put("body", body)
            last.put("timestamp", System.currentTimeMillis().toString())
            prefs.edit().putString(lastKey, last.toString()).apply()

            if (raw != null) {
                val map = JSONObject(raw)
                val minutes = if (map.has("reminderIntervalMinutes") && !map.isNull("reminderIntervalMinutes")) map.getInt("reminderIntervalMinutes") else null
                val useWork = map.optBoolean("use_work_manager", false)
                val useInexact = map.optBoolean("use_inexact", false)
                if (minutes != null && minutes > 0) {
                    if (useWork) {
                        val period = if (minutes < 15) 15L else minutes.toLong()
                        val workRequest = PeriodicWorkRequestBuilder<ReminderWorker>(period, TimeUnit.MINUTES).build()
                        WorkManager.getInstance(context).enqueueUniquePeriodicWork("hydration_reminder", ExistingPeriodicWorkPolicy.REPLACE, workRequest)
                    } else {
                        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        val intent2 = Intent(context, ReminderReceiver::class.java)
                        intent2.action = "com.example.hydro_homie.ACTION_REMIND"
                        val pending2 = PendingIntent.getBroadcast(context, 1001, intent2, if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT else PendingIntent.FLAG_UPDATE_CURRENT)
                        val interval = minutes * 60 * 1000L
                        val triggerAt = System.currentTimeMillis() + interval
                        alarmManager.setInexactRepeating(AlarmManager.RTC_WAKEUP, triggerAt, interval, pending2)
                    }
                }
            }
        } catch (e: Exception) {
            // ignore scheduling errors
        }
    }
}
