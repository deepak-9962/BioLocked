package com.example.bio_locked

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar
import kotlin.math.max
import kotlin.math.min

class MainActivity : FlutterActivity() {
    private val usageChannelName = "com.biolocked.app_usage/methods"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, usageChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isUsageAccessGranted" -> result.success(isUsageAccessGranted())
                    "openUsageAccessSettings" -> {
                        openUsageAccessSettings()
                        result.success(null)
                    }
                    "getUsageByApp" -> handleUsageByApp(call, result)
                    "getUsageByHour" -> handleUsageByHour(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun handleUsageByApp(call: MethodCall, result: MethodChannel.Result) {
        val startMs = call.argument<Number>("startMs")?.toLong()
        val endMs = call.argument<Number>("endMs")?.toLong()
        if (startMs == null || endMs == null || endMs <= startMs) {
            result.error("invalid_args", "startMs/endMs are required and must form a valid range", null)
            return
        }
        if (!isUsageAccessGranted()) {
            result.error("permission_denied", "Usage Access permission not granted", null)
            return
        }
        val manager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val stats = manager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startMs, endMs)
        val byPackageMillis = mutableMapOf<String, Long>()
        stats?.forEach { item ->
            if (item.totalTimeInForeground > 0L) {
                byPackageMillis[item.packageName] =
                    (byPackageMillis[item.packageName] ?: 0L) + item.totalTimeInForeground
            }
        }

        val labels = mutableMapOf<String, String>()
        val rows = byPackageMillis.entries
            .sortedByDescending { it.value }
            .map { entry ->
                mapOf(
                    "packageName" to entry.key,
                    "appLabel" to resolveAppLabel(entry.key, labels),
                    "minutes" to (entry.value / 60000L).toInt(),
                )
            }
        result.success(rows)
    }

    private fun handleUsageByHour(call: MethodCall, result: MethodChannel.Result) {
        val startMs = call.argument<Number>("startMs")?.toLong()
        val endMs = call.argument<Number>("endMs")?.toLong()
        if (startMs == null || endMs == null || endMs <= startMs) {
            result.error("invalid_args", "startMs/endMs are required and must form a valid range", null)
            return
        }
        if (!isUsageAccessGranted()) {
            result.error("permission_denied", "Usage Access permission not granted", null)
            return
        }

        val manager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val events = manager.queryEvents(startMs, endMs)
        val segments = mutableListOf<UsageSegment>()

        var activePackage: String? = null
        var activeStart: Long? = null
        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            when (event.eventType) {
                UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                    if (activePackage != null && activeStart != null && activeStart!! < event.timeStamp) {
                        segments.add(
                            UsageSegment(
                                packageName = activePackage!!,
                                startMs = activeStart!!,
                                endMs = event.timeStamp,
                            )
                        )
                    }
                    activePackage = event.packageName
                    activeStart = event.timeStamp
                }
                UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                    if (activePackage != null &&
                        activeStart != null &&
                        event.packageName == activePackage &&
                        activeStart!! < event.timeStamp
                    ) {
                        segments.add(
                            UsageSegment(
                                packageName = activePackage!!,
                                startMs = activeStart!!,
                                endMs = event.timeStamp,
                            )
                        )
                        activePackage = null
                        activeStart = null
                    }
                }
            }
        }

        if (activePackage != null && activeStart != null && activeStart!! < endMs) {
            segments.add(
                UsageSegment(
                    packageName = activePackage!!,
                    startMs = activeStart!!,
                    endMs = endMs,
                )
            )
        }

        val labels = mutableMapOf<String, String>()
        val buckets = mutableMapOf<String, Long>()
        for (segment in segments) {
            var cursor = max(segment.startMs, startMs)
            val segmentEnd = min(segment.endMs, endMs)
            while (cursor < segmentEnd) {
                val hourStart = floorToHour(cursor)
                val nextHourStart = hourStart + 60L * 60L * 1000L
                val sliceEnd = min(nextHourStart, segmentEnd)
                val dayStart = floorToDay(cursor)
                val hour = hourOf(cursor)
                val key = "$dayStart|$hour|${segment.packageName}"
                buckets[key] = (buckets[key] ?: 0L) + (sliceEnd - cursor)
                cursor = sliceEnd
            }
        }

        val rows = buckets.entries
            .map { (key, millis) ->
                val parts = key.split("|")
                val dayStartMs = parts[0].toLong()
                val hour = parts[1].toInt()
                val packageName = parts[2]
                mapOf(
                    "dayStartMs" to dayStartMs,
                    "hour" to hour,
                    "packageName" to packageName,
                    "appLabel" to resolveAppLabel(packageName, labels),
                    "minutes" to (millis / 60000L).toInt(),
                )
            }
            .sortedWith(
                compareByDescending<Map<String, Any>> { it["dayStartMs"] as Long }
                    .thenByDescending { it["hour"] as Int }
                    .thenByDescending { it["minutes"] as Int }
            )

        result.success(rows)
    }

    private fun isUsageAccessGranted(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageAccessSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun resolveAppLabel(packageName: String, cache: MutableMap<String, String>): String {
        val cached = cache[packageName]
        if (cached != null) return cached
        val label = try {
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(appInfo)?.toString() ?: packageName
        } catch (_: Exception) {
            packageName
        }
        cache[packageName] = label
        return label
    }

    private fun floorToHour(timestamp: Long): Long {
        val cal = Calendar.getInstance()
        cal.timeInMillis = timestamp
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    private fun floorToDay(timestamp: Long): Long {
        val cal = Calendar.getInstance()
        cal.timeInMillis = timestamp
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    private fun hourOf(timestamp: Long): Int {
        val cal = Calendar.getInstance()
        cal.timeInMillis = timestamp
        return cal.get(Calendar.HOUR_OF_DAY)
    }
}

data class UsageSegment(
    val packageName: String,
    val startMs: Long,
    val endMs: Long,
)
