package com.example.hydro_homie

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import androidx.core.app.NotificationCompat
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.app.NotificationChannel
import android.content.SharedPreferences
import org.json.JSONObject

class ReminderWorker(appContext: Context, params: WorkerParameters) : CoroutineWorker(appContext, params) {
    override suspend fun doWork(): Result {
        val context = applicationContext
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelId = "hydration_reminders"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "Hydration Reminders", NotificationManager.IMPORTANCE_DEFAULT)
            notificationManager.createNotificationChannel(channel)
        }
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
        }

        try {
            val prefs: SharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val lastKey = "flutter.last_native_notification_v1"
            val now = System.currentTimeMillis()
            val last = JSONObject()
            last.put("id", 1001)
            last.put("title", title)
            last.put("body", body)
            last.put("timestamp", now.toString())
            prefs.edit().putString(lastKey, last.toString()).apply()
        } catch (e: Exception) {
        }

        return Result.success()
    }
}
