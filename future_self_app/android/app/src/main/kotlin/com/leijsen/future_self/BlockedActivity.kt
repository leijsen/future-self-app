package com.leijsen.future_self

import android.app.Activity
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Bundle
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Full-screen block page: launched by the accessibility service when a limited app
 * comes to the front over quota (or during focus mode). Shows why it was blocked and a contract reminder.
 *
 * For daily limits it re-checks real usage time via UsageStatsManager first,
 * and does not block when under quota (accessibility events carry no duration).
 */
class BlockedActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val pkg = intent.getStringExtra(OverlayAccessibilityService.EXTRA_PKG) ?: ""
        val reason = intent.getStringExtra(OverlayAccessibilityService.EXTRA_REASON) ?: "limit"

        if (reason == "limit") {
            val prefs = getSharedPreferences(OverlayAccessibilityService.PREFS, Context.MODE_PRIVATE)
            val limitMinutes = findLimitMinutes(prefs, pkg)
            val usedSeconds = todayUsedSeconds(pkg)
            if (usedSeconds < limitMinutes * 60) {
                finish()  // under quota - false alarm, let it through
                return
            }
        }

        window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(0xFF1A1B2E.toInt())
            setPadding(64, 64, 64, 64)
        }

        val title = TextView(this).apply {
            text = if (reason == "focus") "Focus mode is running" else "Today's quota is used up"
            textSize = 24f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = Gravity.CENTER
        }

        val body = TextView(this).apply {
            text = if (reason == "focus") {
                "This app is on your focus block list.\nGo back and keep going - your future self will thank you."
            } else {
                val m = todayUsedSeconds(pkg) / 60
                "You have spent $m minutes on it today.\nThis is the quota you set for yourself when you signed."
            }
            textSize = 16f
            setTextColor(0xFFB8B8CC.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 32, 0, 0)
        }

        val back = Button(this).apply {
            text = "Back to discipline"
            setOnClickListener { finish() }
        }

        root.addView(title)
        root.addView(body)
        val lp = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        )
        lp.topMargin = 64
        root.addView(back, lp)

        setContentView(root)
    }

    private fun findLimitMinutes(prefs: android.content.SharedPreferences, pkg: String): Int {
        val raw = prefs.getString("limits", "") ?: return 0
        for (entry in raw.split('\u0002')) {
            val parts = entry.split('\u0001')
            if (parts.size < 3) continue
            if (pkg in parts[2].split('|')) return parts[1].toIntOrNull() ?: 0
        }
        return 0
    }

    private fun todayUsedSeconds(pkg: String): Int {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val startOfDay = now - (now % (24 * 60 * 60 * 1000))
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startOfDay, now)
            ?: return 0
        var total = 0L
        for (s in stats) {
            if (s.packageName == pkg) total += s.totalTimeInForeground
        }
        return (total / 1000).toInt()
    }
}
