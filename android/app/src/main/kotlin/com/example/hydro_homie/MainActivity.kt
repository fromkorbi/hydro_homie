package com.example.hydro_homie

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit
import android.util.Log

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.hydro_homie/notifications"
    private val NOTIFY_CHANNEL = "com.example.hydro_homie/notify"

    companion object {
        var methodChannel: MethodChannel? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )
        methodChannel = channel
        
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleNativeReminder" -> {
                    val args = call.arguments as Map<*, *>
                    val minutes = (args["minutes"] as Number).toInt()
                    val useWork = args["useWorkManager"] as? Boolean ?: false
                    val useInexact = args["useInexact"] as? Boolean ?: false
                    scheduleNativeReminder(minutes, useWork, useInexact)
                    result.success(null)
                }

                "cancelNativeReminders" -> {
                    cancelNativeReminders()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun scheduleNativeReminder(minutes: Int, useWork: Boolean, useInexact: Boolean) {
        Log.i("MainActivity", "scheduleNativeReminder: minutes=$minutes useWork=$useWork useInexact=$useInexact")

        if (useWork) {
            val period = if (minutes < 15) 15L else minutes.toLong()
            val workRequest =
                PeriodicWorkRequestBuilder<ReminderWorker>(period, TimeUnit.MINUTES).build()

            WorkManager.getInstance(this).enqueueUniquePeriodicWork(
                "hydration_reminder",
                ExistingPeriodicWorkPolicy.REPLACE,
                workRequest
            )
            return
        }

        val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, ReminderReceiver::class.java)
        intent.action = "com.example.hydro_homie.ACTION_REMIND"

        val pending = PendingIntent.getBroadcast(
            this,
            1001,
            intent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            else PendingIntent.FLAG_UPDATE_CURRENT
        )

        val interval = minutes * 60 * 1000L
        val triggerAt = System.currentTimeMillis() + interval

        alarmManager.setInexactRepeating(
            AlarmManager.RTC_WAKEUP,
            triggerAt,
            interval,
            pending
        )
    }

    private fun cancelNativeReminders() {

        try {
            val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager
            val intent = Intent(this, ReminderReceiver::class.java)
            intent.action = "com.example.hydro_homie.ACTION_REMIND"

            val pending = PendingIntent.getBroadcast(
                this,
                1001,
                intent,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                else PendingIntent.FLAG_UPDATE_CURRENT
            )

            alarmManager.cancel(pending)
        } catch (_: Exception) {
        }

        try {
            WorkManager.getInstance(this).cancelUniqueWork("hydration_reminder")
        } catch (_: Exception) {
        }
    }
}
