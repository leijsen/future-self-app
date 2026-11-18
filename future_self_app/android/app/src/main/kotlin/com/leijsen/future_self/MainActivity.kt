package com.leijsen.future_self

import android.app.usage.UsageStatsManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "screen_time_control"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "probeCapability" -> result.success(probeCapability())
                    "getUsageReport" -> getUsageReport(call.argument<List<Map<String, Any>>>("groups"), result)
                    "setAppLimits" -> {
                        // Limits are read by the blocking service: write SharedPreferences for
                        // OverlayAccessibilityService to consume
                        val limits = call.argument<List<Map<String, Any>>>("limits") ?: emptyList()
                        saveLimits(limits)
                        result.success(null)
                    }
                    "enableFocusMode" -> {
                        val groupIds = call.argument<List<String>>("groupIds") ?: emptyList()
                        prefs().edit().putString("focus_blocked_groups", groupIds.joinToString(","))
                            .putBoolean("focus_mode", true).apply()
                        result.success(null)
                    }
                    "disableFocusMode" -> {
                        prefs().edit().putBoolean("focus_mode", false)
                            .remove("focus_blocked_groups").apply()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun prefs() =
        getSharedPreferences("screen_time_control", Context.MODE_PRIVATE)

    private fun probeCapability(): Int {
        val hasUsageAccess = hasUsageAccess()
        val hasAccessibility = OverlayAccessibilityService.isRunning
        return when {
            hasUsageAccess && hasAccessibility -> 0  // systemLevel
            hasUsageAccess -> 1                       // statisticsOnly
            else -> 2                                 // none
        }
    }

    private fun hasUsageAccess(): Boolean {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val stats = usm.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            now - 24 * 60 * 60 * 1000, now
        )
        return stats != null && stats.isNotEmpty()
    }

    private fun saveLimits(limits: List<Map<String, Any>>) {
        val sb = StringBuilder()
        for (limit in limits) {
            val groupId = limit["groupId"] as? String ?: continue
            val minutes = (limit["dailyLimitMinutes"] as? Number)?.toInt() ?: continue
            val packages = (limit["packageNames"] as? List<*>)?.joinToString("|") { it.toString() } ?: ""
            sb.append(groupId).append('\u0001')
                .append(minutes).append('\u0001')
                .append(packages).append('\u0002')
        }
        prefs().edit().putString("limits", sb.toString()).apply()
    }

    private fun getUsageReport(groupsArg: List<Map<String, Any>>?, result: MethodChannel.Result) {
        if (!hasUsageAccess()) {
            result.error("NO_ACCESS", "Usage access not granted", null)
            return
        }
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val startOfDay = now - (now % (24 * 60 * 60 * 1000))

        val stats = usm.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, startOfDay, now
        ) ?: emptyList()
        val usedByPackage = HashMap<String, Long>()
        for (s in stats) {
            usedByPackage[s.packageName] = (usedByPackage[s.packageName] ?: 0L) + s.totalTimeInForeground
        }

        val groups = groupsArg ?: emptyList()
        val report = groups.map { g ->
            val groupId = g["groupId"] as? String ?: ""
            val limitMinutes = (g["dailyLimitMinutes"] as? Number)?.toInt() ?: 0
            val packages = (g["packageNames"] as? List<*>)?.map { it.toString() } ?: emptyList()
            var usedMs = 0L
            for (p in packages) usedMs += usedByPackage[p] ?: 0L
            mapOf(
                "groupId" to groupId,
                "usedSeconds" to (usedMs / 1000).toInt(),
                "limitSeconds" to limitMinutes * 60
            )
        }
        result.success(mapOf("groups" to report))
    }
}
