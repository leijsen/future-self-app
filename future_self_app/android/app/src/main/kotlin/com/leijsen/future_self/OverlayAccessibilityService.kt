package com.leijsen.future_self

import android.content.Context
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import io.flutter.plugin.common.MethodChannel

/**
 * 无障碍服务：监听前台应用切换。
 * 命中被限额/专注模式屏蔽的包名时，拉起拦截页（BlockedActivity）。
 *
 * 数据来源：MainActivity 写入的 SharedPreferences（limits / focus_mode）。
 */
class OverlayAccessibilityService : android.accessibilityservice.AccessibilityService() {

    companion object {
        @Volatile var isRunning: Boolean = false
            private set

        const val PREFS = "screen_time_control"

        /** groupId \u0001 minutes \u0001 pkg|pkg|pkg \u0002 ... */
        private const val LIMITS_KEY = "limits"
        private const val FOCUS_KEY = "focus_mode"
        private const val FOCUS_GROUPS_KEY = "focus_blocked_groups"
        const val EXTRA_PKG = "blocked_package"
        const val EXTRA_REASON = "reason"
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        isRunning = true
        val info = serviceInfo
        info.feedbackType = android.accessibilityservice.AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.flags = info.flags or android.accessibilityservice.AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
        serviceInfo = info
    }

    override fun onDestroy() {
        isRunning = false
        super.onDestroy()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return
        if (pkg == packageName) return  // 自己的界面不拦

        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)

        // 专注模式：所有屏蔽组全拦
        if (prefs.getBoolean(FOCUS_KEY, false)) {
            val focusGroups = prefs.getString(FOCUS_GROUPS_KEY, "")!!.split(",").filter { it.isNotBlank() }
            val allBlocked = collectBlockedPackages(prefs, focusGroups)
            if (pkg in allBlocked) {
                launchBlocked(pkg, "focus")
                return
            }
        }

        // 日常限额：超时才拦（时长由 BlockedActivity 二次确认，见 shouldBlockForLimit）
        val limited = collectLimitedPackages(prefs)
        if (pkg in limited) {
            launchBlocked(pkg, "limit")
        }
    }

    /** 解析 limits 字符串 → Map(pkg → groupId) */
    private fun collectLimitedPackages(prefs: android.content.SharedPreferences): Set<String> {
        val raw = prefs.getString(LIMITS_KEY, "") ?: return emptySet()
        val set = HashSet<String>()
        for (entry in raw.split('\u0002')) {
            val parts = entry.split('\u0001')
            if (parts.size < 3) continue
            for (p in parts[2].split('|')) {
                if (p.isNotBlank()) set.add(p)
            }
        }
        return set
    }

    private fun collectBlockedPackages(
        prefs: android.content.SharedPreferences,
        groupIds: List<String>
    ): Set<String> {
        val raw = prefs.getString(LIMITS_KEY, "") ?: return emptySet()
        val required = groupIds.toSet()
        val set = HashSet<String>()
        for (entry in raw.split('\u0002')) {
            val parts = entry.split('\u0001')
            if (parts.size < 3) continue
            if (parts[0] !in required) continue
            for (p in parts[2].split('|')) {
                if (p.isNotBlank()) set.add(p)
            }
        }
        return set
    }

    private fun launchBlocked(pkg: String, reason: String) {
        // 防抖：同一包 3 秒内不重复拉起
        val now = System.currentTimeMillis()
        if (now - lastLaunchAt < 3000 && pkg == lastPkg) return
        lastLaunchAt = now
        lastPkg = pkg

        val intent = Intent(this, BlockedActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            putExtra(EXTRA_PKG, pkg)
            putExtra(EXTRA_REASON, reason)
        }
        startActivity(intent)
    }

    private var lastLaunchAt = 0L
    private var lastPkg = ""

    override fun onInterrupt() {}
}
