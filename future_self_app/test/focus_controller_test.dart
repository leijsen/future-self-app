import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_self/models/contract.dart';
import 'package:future_self/state/focus_controller.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('focus_test');
    Hive.init(dir.path);
  });

  test('第1档退出挑战：立即允许退出', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(focusProvider.notifier);

    controller.startSession(25, ExitChallengeLevel.gentle, null);
    expect(container.read(focusProvider).status, FocusStatus.running);

    final allowed = controller.requestExit();
    expect(allowed, isTrue);
    // 放弃后状态由 running → abandoned
    expect(container.read(focusProvider).status, FocusStatus.abandoned);
  });

  test('第2档退出挑战：不允许直接退出，需输入文字确认', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(focusProvider.notifier);

    controller.startSession(25, ExitChallengeLevel.firm, '背单词');
    final allowed = controller.requestExit();
    expect(allowed, isFalse);
    expect(container.read(focusProvider).status, FocusStatus.running);

    controller.confirmExitWithText();
    expect(container.read(focusProvider).status, FocusStatus.abandoned);
  });

  test('第3档退出挑战：倒计时未结束不许退出', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(focusProvider.notifier);

    controller.startSession(25, ExitChallengeLevel.strict, null);
    final allowed = controller.requestExit();
    expect(allowed, isFalse);
    expect(container.read(focusProvider).isChallengeActive, isTrue);

    // 倒计时还剩 59 秒 → 拒绝退出
    controller.confirmExitAfterCountdown();
    expect(container.read(focusProvider).status, FocusStatus.running);

    // 放弃挑战 → 清除倒计时，继续专注
    controller.cancelChallenge();
    expect(container.read(focusProvider).isChallengeActive, isFalse);
    expect(container.read(focusProvider).status, FocusStatus.running);
  });

  test('reset 回到 idle 初始状态', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(focusProvider.notifier);

    controller.startSession(25, ExitChallengeLevel.gentle, null);
    controller.reset();
    expect(container.read(focusProvider).status, FocusStatus.idle);
  });
}
