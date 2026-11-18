package com.leijsen.future_self

import android.content.Context
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import io.flutter.plugin.common.MethodChannel

/**
 * Accessibility service: watches foreground app switches.
 * When a limited / focus-blocked package comes to the front, launches the block page (BlockedActivity).
 *
 * Data source: SharedPreferences written by MainActivity (limits / focus_mode).
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
        if (pkg == packageName) return  // never block our own UI

        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)

        // Focus mode: block everything in the blocked groups
        if (prefs.getBoolean(FOCUS_KEY, false)) {
            val focusGroups = prefs.getString(FOCUS_GROUPS_KEY, "")!!.split(",").filter { it.isNotBlank() }
            val allBlocked = collectBlockedPackages(prefs, focusGroups)
            if (pkg in allBlocked) {
                launchBlocked(pkg, "focus")
                return
            }
        }

        // Daily limits: block only when over quota (BlockedActivity double-checks the duration, see shouldBlockForLimit)
        val limited = collectLimitedPackages(prefs)
        if (pkg in limited) {
            launchBlocked(pkg, "limit")
        }
    }

    /** Parse the limits string into Map(pkg -> groupId) */
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
        // Debounce: do not relaunch for the same package within 3s
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
