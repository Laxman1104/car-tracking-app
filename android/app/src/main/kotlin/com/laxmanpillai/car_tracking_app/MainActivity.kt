package com.laxmanpillai.car_tracking_app

import android.content.ActivityNotFoundException
import android.content.Intent
import android.provider.CalendarContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "car_tracker/service_calendar",
        ).setMethodCallHandler { call, result ->
            if (call.method != "addServiceReminder") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val title = call.argument<String>("title")
            val description = call.argument<String>("description")
            val startMillis = call.argument<Number>("startMillis")?.toLong()
            if (title == null || startMillis == null) {
                result.error("INVALID_EVENT", "Calendar event details are incomplete.", null)
                return@setMethodCallHandler
            }
            val intent = Intent(Intent.ACTION_INSERT).apply {
                data = CalendarContract.Events.CONTENT_URI
                putExtra(CalendarContract.Events.TITLE, title)
                putExtra(CalendarContract.Events.DESCRIPTION, description)
                putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, startMillis)
                putExtra(CalendarContract.EXTRA_EVENT_END_TIME, startMillis + 60 * 60 * 1000)
            }
            try {
                startActivity(intent)
                result.success(null)
            } catch (_: ActivityNotFoundException) {
                result.error("NO_CALENDAR", "No calendar app is available.", null)
            }
        }
    }
}
