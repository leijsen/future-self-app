import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

/// 系统级使用控制的能力级别
enum ControlCapability {
  /// 第一层：系统级限制（Android 无障碍拦截 / iOS FamilyControls）
  systemLevel,

  /// 第二层：仅能统计使用时长（到时强提醒 + 劝导页）
  statisticsOnly,

  /// 第三层：什么都拿不到（仅应用内专注计时）
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

  /// Android 包名列表（iOS 由 FamilyControls 托管，无需包名）
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

/// 平台无关的使用控制接口。
/// 各平台通过 PlatformChannel 提供实现；不可用时走降级路径。
abstract class ScreenTimeControl {
  /// 异步探测原生能力（MethodChannel 只能异步调用）
  Future<ControlCapability> probeCapability();
  Future<void> setAppLimits(List<AppGroupLimit> limits);
  Future<void> enableFocusMode(List<String> blockedGroupIds);
  Future<void> disableFocusMode();
  Future<UsageReport> getUsageReport();
}

/// MethodChannel 实现。原生侧未注册方法时抛 MissingPluginException，
/// 视为无原生能力 → 降级。
class NativeScreenTimeControl implements ScreenTimeControl {
  static const _channel = MethodChannel('screen_time_control');

  @override
  Future<ControlCapability> probeCapability() async {
    try {
      final level = await _channel.invokeMethod<int>('probeCapability');
      // 原生侧返回 0=systemLevel 1=statisticsOnly 2=none
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

/// 降级实现：无原生能力时（web / 模拟器），返回演示数据。
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
    // Web 演示模式：返回静态示例数据，让 UI 可以完整演示
    final now = DateTime.now();
    // 用日期做伪随机种子，让每天的数据略有变化
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
