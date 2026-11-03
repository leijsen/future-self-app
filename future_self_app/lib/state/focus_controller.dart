import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/contract.dart';
import '../platform/screen_time_control.dart';

enum FocusStatus { idle, running, completed, abandoned }

class FocusSessionState {
  const FocusSessionState({
    this.status = FocusStatus.idle,
    this.startedAt,
    this.plannedMinutes,
    this.exitChallengeLevel = ExitChallengeLevel.firm,
    this.challengeDeadline,
    this.commitmentText,
    this.hasEverStarted = false,
  });

  final FocusStatus status;
  final DateTime? startedAt;
  final int? plannedMinutes;

  /// 退出挑战进行中的截止时刻（第 3 档倒计时用）
  final DateTime? challengeDeadline;
  final ExitChallengeLevel exitChallengeLevel;
  final String? commitmentText;

  /// 本次 App 运行期间是否启动过会话。
  /// 用于区分"从未启动（刷新后状态丢失）"与"会话结束后 reset 归零"，
  /// 防止 idle 弹回逻辑劫持刚结束的会话跳转。
  final bool hasEverStarted;

  FocusSessionState copyWith({
    FocusStatus? status,
    DateTime? startedAt,
    int? plannedMinutes,
    DateTime? challengeDeadline,
    ExitChallengeLevel? exitChallengeLevel,
    String? commitmentText,
    bool? hasEverStarted,
  }) {
    return FocusSessionState(
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      challengeDeadline: challengeDeadline ?? this.challengeDeadline,
      exitChallengeLevel: exitChallengeLevel ?? this.exitChallengeLevel,
      commitmentText: commitmentText ?? this.commitmentText,
      hasEverStarted: hasEverStarted ?? this.hasEverStarted,
    );
  }

  /// 剩余秒数（基于 startedAt 与 plannedMinutes 推算，进程被杀也可恢复）
  int get remainingSeconds {
    if (startedAt == null || plannedMinutes == null) return 0;
    final elapsed = DateTime.now().difference(startedAt!).inSeconds;
    final total = plannedMinutes! * 60;
    return (total - elapsed).clamp(0, total);
  }

  bool get isChallengeActive =>
      status == FocusStatus.running && challengeDeadline != null;

  Duration get challengeRemaining {
    if (challengeDeadline == null) return Duration.zero;
    return challengeDeadline!.difference(DateTime.now());
  }
}

class FocusController extends Notifier<FocusSessionState> {
  Timer? _ticker;

  @override
  FocusSessionState build() {
    ref.onDispose(() => _ticker?.cancel());
    return const FocusSessionState();
  }

  /// 启动专注会话
  void startSession(int minutes, ExitChallengeLevel level, String? commitment) {
    _ticker?.cancel();
    state = FocusSessionState(
      status: FocusStatus.running,
      startedAt: DateTime.now(),
      plannedMinutes: minutes,
      exitChallengeLevel: level,
      commitmentText: commitment,
      hasEverStarted: true,
    );
    // 联动原生拦截：专注期间屏蔽所有启用中的分组（原生不可用时静默降级）
    _enabledGroupIds().then((ids) => _safeCall((c) => c.enableFocusMode(ids)));
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds <= 0) {
        _complete();
      } else {
        // 触发重建以刷新倒计时显示
        state = state.copyWith();
      }
    });
  }

  Future<List<String>> _enabledGroupIds() async {
    final box = await Hive.openBox('app_groups');
    final enabled = box.get('enabled_group_ids') as List?;
    if (enabled == null) {
      // 未设置过限额页时按契约兜底：屏蔽短视频/短剧/游戏三类
      return ['short_video', 'short_drama', 'game'];
    }
    return enabled.cast<String>();
  }

  Future<void> _safeCall(Future<void> Function(ScreenTimeControl) action) async {
    try {
      await action(ref.read(screenTimeControlProvider));
    } catch (_) {
      // 原生未注册（web/模拟器）——静默降级
    }
  }

  void _complete() {
    _ticker?.cancel();
    _safeCall((c) => c.disableFocusMode());
    final finished = state;
    state = finished.copyWith(status: FocusStatus.completed);
    _recordSession(finished, completed: true);
  }

  /// 用户尝试提前退出 —— 返回是否被允许立即退出
  bool requestExit() {
    if (state.status != FocusStatus.running) return true;

    switch (state.exitChallengeLevel) {
      case ExitChallengeLevel.gentle:
        _abandon();
        return true;
      case ExitChallengeLevel.firm:
        // 第 2 档：需要输入承诺文字，由 UI 层调用 confirmExitWithText
        return false;
      case ExitChallengeLevel.strict:
        // 第 3 档：进入 60 秒强制倒计时，由 confirmExitAfterCountdown 结束
        state = state.copyWith(
          challengeDeadline: DateTime.now().add(const Duration(seconds: 60)),
        );
        return false;
    }
  }

  /// 第 2 档：输入了自己写的承诺文字后允许退出
  void confirmExitWithText() => _abandon();

  /// 第 3 档：倒计时结束后允许退出
  void confirmExitAfterCountdown() {
    if (state.challengeRemaining > Duration.zero) return;
    _abandon();
  }

  void cancelChallenge() {
    state = FocusSessionState(
      status: state.status,
      startedAt: state.startedAt,
      plannedMinutes: state.plannedMinutes,
      exitChallengeLevel: state.exitChallengeLevel,
      commitmentText: state.commitmentText,
      hasEverStarted: true,
    );
  }

  void _abandon() {
    _ticker?.cancel();
    _safeCall((c) => c.disableFocusMode());
    final session = state;
    state = session.copyWith(status: FocusStatus.abandoned, challengeDeadline: null);
    _recordSession(session, completed: false);
  }

  /// 会话结束回到 idle，供 UI 在展示结果后调用。
  /// 保留 hasEverStarted，让 idle 弹回逻辑不再触发。
  void reset() {
    _ticker?.cancel();
    state = FocusSessionState(hasEverStarted: state.hasEverStarted);
  }

  Future<void> _recordSession(FocusSessionState session,
      {required bool completed}) async {
    if (session.startedAt == null || session.plannedMinutes == null) return;
    final box = await Hive.openBox('focus_sessions');
    await box.add({
      'startedAt': session.startedAt!.toIso8601String(),
      'plannedMinutes': session.plannedMinutes,
      'completed': completed,
      'exitChallengeLevel': session.exitChallengeLevel.name,
      'ts': DateTime.now().toIso8601String(),
    });
  }
}

final focusProvider = NotifierProvider<FocusController, FocusSessionState>(
  FocusController.new,
);

class FocusStats {
  static Future<int> todayFocusedMinutes() async {
    final box = await Hive.openBox('focus_sessions');
    final today = DateTime.now();
    var minutes = 0;
    for (final raw in box.values) {
      final m = Map<String, dynamic>.from(raw as Map);
      if (m['completed'] != true) continue;
      final started = DateTime.parse(m['startedAt'] as String);
      if (started.year == today.year &&
          started.month == today.month &&
          started.day == today.day) {
        minutes += m['plannedMinutes'] as int;
      }
    }
    return minutes;
  }

  static Future<int> completedCount() async {
    final box = await Hive.openBox('focus_sessions');
    return box.values
        .where((raw) => (raw as Map)['completed'] == true)
        .length;
  }
}
