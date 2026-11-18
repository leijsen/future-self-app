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

  /// Deadline for an in-progress exit challenge (used by the tier-3 countdown)
  final DateTime? challengeDeadline;
  final ExitChallengeLevel exitChallengeLevel;
  final String? commitmentText;

  /// Whether a session has been started during this app run.
  /// Distinguishes "never started (state lost on refresh)" from "reset to zero after a session ends",
  /// so the idle-bounce logic cannot hijack the navigation of a just-finished session.
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

  /// Seconds left (derived from startedAt and plannedMinutes, recoverable after process death)
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

  /// Start a focus session
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
    // Link to native blocking: block every enabled group during focus (silently degrades when native is unavailable)
    _enabledGroupIds().then((ids) => _safeCall((c) => c.enableFocusMode(ids)));
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds <= 0) {
        _complete();
      } else {
        // Trigger a rebuild to refresh the countdown display
        state = state.copyWith();
      }
    });
  }

  Future<List<String>> _enabledGroupIds() async {
    final box = await Hive.openBox('app_groups');
    final enabled = box.get('enabled_group_ids') as List?;
    if (enabled == null) {
      // Fall back to the contract when the limits page was never configured: block short video / short drama / games
      return ['short_video', 'short_drama', 'game'];
    }
    return enabled.cast<String>();
  }

  Future<void> _safeCall(Future<void> Function(ScreenTimeControl) action) async {
    try {
      await action(ref.read(screenTimeControlProvider));
    } catch (_) {
      // Native side unregistered (web/emulator) - silently degrade
    }
  }

  void _complete() {
    _ticker?.cancel();
    _safeCall((c) => c.disableFocusMode());
    final finished = state;
    state = finished.copyWith(status: FocusStatus.completed);
    _recordSession(finished, completed: true);
  }

  /// The user tries to exit early - returns whether immediate exit is allowed
  bool requestExit() {
    if (state.status != FocusStatus.running) return true;

    switch (state.exitChallengeLevel) {
      case ExitChallengeLevel.gentle:
        _abandon();
        return true;
      case ExitChallengeLevel.firm:
        // Tier 2: requires the commitment text; the UI calls confirmExitWithText
        return false;
      case ExitChallengeLevel.strict:
        // Tier 3: enter the forced 60-second countdown, ended by confirmExitAfterCountdown
        state = state.copyWith(
          challengeDeadline: DateTime.now().add(const Duration(seconds: 60)),
        );
        return false;
    }
  }

  /// Tier 2: exit is allowed once the self-written commitment text is entered
  void confirmExitWithText() => _abandon();

  /// Tier 3: exit is allowed after the countdown ends
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

  /// Return to idle once the session ends; called by the UI after showing the result.
  /// Keeps hasEverStarted so the idle-bounce logic no longer fires.
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
