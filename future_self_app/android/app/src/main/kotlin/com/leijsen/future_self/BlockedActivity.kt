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
 * 全屏拦截页：被限 App 切前台且额度已超时（或专注模式）时由
 * 无障碍服务拉起。展示被拦原因与契约提醒，提供"回来自律"按钮。
 *
 * 限额情况下会先用 UsageStatsManager 复核当日真实使用时长，
 * 未超时不拦（无障碍事件本身不携带时长信息）。
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
                finish()  // 额度未用完，误报，放行
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
            text = if (reason == "focus") "专注模式进行中" else "今日额度已用完"
            textSize = 24f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = Gravity.CENTER
        }

        val body = TextView(this).apply {
            text = if (reason == "focus") {
                "这个 App 在你的专注名单里。\n回去继续，未来的你会感谢现在的你。"
            } else {
                val m = todayUsedSeconds(pkg) / 60
                "今天已经刷了 $m 分钟。\n这是你签契约时自己定的额度。"
            }
            textSize = 16f
            setTextColor(0xFFB8B8CC.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 32, 0, 0)
        }

        val back = Button(this).apply {
            text = "回来自律"
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
