import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

/// Capability levels for system-level usage control
enum ControlCapability {
  /// Tier 1: system-level enforcement (Android accessibility blocking / iOS FamilyControls)
  systemLevel,

  /// Tier 2: usage statistics only (hard reminder plus a persuasion page when the limit is hit)
  statisticsOnly,

  /// Tier 3: nothing available (in-app focus timer only)
  none,
}

class AppGroupLimit {
  const AppGroupLimit({
    required this.groupId,
    required this.name,
    required this.dailyLimitMinutes,
    this.packageNames = const [],
  });

  final String groupId;
  final String name;
  final int dailyLimitMinutes;

  /// Android package names (iOS uses FamilyControls and needs none)
  final List<String> packageNames;
}

class GroupUsage {
  const GroupUsage({
    required this.groupId,
    required this.usedSeconds,
    required this.limitSeconds,
  });

  final String groupId;
  final int usedSeconds;
  final int limitSeconds;

  int get remainingSeconds => (limitSeconds - usedSeconds).clamp(0, limitSeconds);
  bool get exceeded => usedSeconds >= limitSeconds;
}

class UsageReport {
  const UsageReport({required this.groups});
  final List<GroupUsage> groups;
}

/// Platform-agnostic usage-control interface.
/// Each platform implements it over a PlatformChannel; falls back to a degraded path when unavailable.
abstract class ScreenTimeControl {
  /// Probe native capability asynchronously (MethodChannel calls can only be async)
  Future<ControlCapability> probeCapability();
  Future<void> setAppLimits(List<AppGroupLimit> limits);
  Future<void> enableFocusMode(List<String> blockedGroupIds);
  Future<void> disableFocusMode();
  Future<UsageReport> getUsageReport();
}

/// MethodChannel implementation. Throws MissingPluginException when the native side registers nothing,
/// which counts as no native capability, so we degrade.
class NativeScreenTimeControl implements ScreenTimeControl {
  static const _channel = MethodChannel('screen_time_control');

  @override
  Future<ControlCapability> probeCapability() async {
    try {
      final level = await _channel.invokeMethod<int>('probeCapability');
      // Native side returns 0=systemLevel 1=statisticsOnly 2=none
      switch (level) {
        case 0:
          return ControlCapability.systemLevel;
        case 1:
          return ControlCapability.statisticsOnly;
        default:
          return ControlCapability.none;
      }
    } on MissingPluginException {
      return ControlCapability.none;
    } on PlatformException {
      return ControlCapability.none;
    }
  }

  @override
  Future<void> setAppLimits(List<AppGroupLimit> limits) async {
    await _channel.invokeMethod('setAppLimits', {
      'limits': limits
          .map((l) => {
                'groupId': l.groupId,
                'name': l.name,
                'dailyLimitMinutes': l.dailyLimitMinutes,
                'packageNames': l.packageNames,
              })
          .toList(),
    });
  }

  @override
  Future<void> enableFocusMode(List<String> blockedGroupIds) async {
    await _channel
        .invokeMethod('enableFocusMode', {'groupIds': blockedGroupIds});
  }

  @override
  Future<void> disableFocusMode() async {
    await _channel.invokeMethod('disableFocusMode');
  }

  @override
  Future<UsageReport> getUsageReport() async {
    final raw = await _channel.invokeMethod('getUsageReport');
    final map = Map<String, dynamic>.from(raw as Map);
    return UsageReport(
      groups: (map['groups'] as List)
          .map((g) => GroupUsage(
                groupId: g['groupId'] as String,
                usedSeconds: g['usedSeconds'] as int,
                limitSeconds: g['limitSeconds'] as int,
              ))
          .toList(),
    );
  }
}

/// Fallback implementation: returns demo data when no native capability exists (web / emulator).
class LocalOnlyScreenTimeControl implements ScreenTimeControl {
  @override
  Future<ControlCapability> probeCapability() async =>
      ControlCapability.none;
  @override
  Future<void> setAppLimits(List<AppGroupLimit> limits) async {}
  @override
  Future<void> enableFocusMode(List<String> blockedGroupIds) async {}
  @override
  Future<void> disableFocusMode() async {}
  @override
  Future<UsageReport> getUsageReport() async =>
      UsageReport(groups: _fakeReport());

  List<GroupUsage> _fakeReport() {
    // Web demo mode: static sample data so the UI can be demonstrated end to end
    final now = DateTime.now();
    // Seed with the day of the month so the numbers shift a little day to day
    final dayFactor = (now.day % 5) * 60;
    return [
      GroupUsage(groupId: 'short_video', usedSeconds: 1800 + dayFactor, limitSeconds: 3600),
      GroupUsage(groupId: 'game', usedSeconds: 900, limitSeconds: 1800),
    ];
  }
}

final screenTimeControlProvider = Provider<ScreenTimeControl>((ref) {
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    return NativeScreenTimeControl();
  }
  return LocalOnlyScreenTimeControl();
});
