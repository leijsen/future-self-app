import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_self/models/contract.dart';
import 'package:future_self/pages/focus/exit_challenge_page.dart';
import 'package:future_self/pages/focus/focus_active_page.dart';
import 'package:future_self/state/focus_controller.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';

// 下面 find.text(...) 用的是应用当前的英文 UI 文案，是功能性断言，不能翻译成中文。
// The find.text(...) calls below match the app's current English UI copy.
// They are functional assertions and must not be localized back to Chinese.
Widget appWithRouter(ProviderContainer container) {
  final router = GoRouter(
    initialLocation: '/focus/active',
    routes: [
      GoRoute(
        path: '/focus/active',
        builder: (_, _) => const FocusActivePage(),
      ),
      GoRoute(
        path: '/focus/exit-challenge',
        builder: (_, _) => const ExitChallengePage(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Center(child: Text('HOME'))),
      ),
      GoRoute(
        path: '/focus',
        builder: (_, _) => const Scaffold(body: Center(child: Text('FOCUS_START'))),
      ),
    ],
  );
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('focus_flow_test');
    Hive.init(dir.path);
  });

  testWidgets(
      'firm: 点提前退出跳到挑战页；点"算了再撑一会儿"回专注页且会话仍在进行 / '
      'firm: early exit opens the challenge page; "Never mind" returns to focus with the session still running',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(() {
      container.read(focusProvider.notifier).reset();
      container.dispose();
    });
    container
        .read(focusProvider.notifier)
        .startSession(25, ExitChallengeLevel.firm, 'test intent');

    await tester.pumpWidget(appWithRouter(container));
    await tester.pump();

    // 点提前退出 → 挑战页出现
    // Tap "exit early" → the challenge page appears
    await tester.tap(find.text("I can't hold on - exit early"));
    await tester.pumpAndSettle();
    expect(find.text('Really give up?'), findsOneWidget);

    // 点"算了，我再撑一会儿" → 回专注页，会话未中断
    // Tap "Never mind" → back to focus, the session is not interrupted
    await tester.tap(find.text("Never mind, I'll hold on a bit longer"));
    await tester.pumpAndSettle();
    expect(find.text('Focusing'), findsOneWidget);
    expect(container.read(focusProvider).status, FocusStatus.running);

    container.read(focusProvider.notifier).reset();
  });

  testWidgets(
      'strict: 挑战页倒计时内无确认按钮，点撑一会儿回去继续专注 / '
      'strict: no confirm button during the countdown; "Never mind" goes back to focus',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(() {
      container.read(focusProvider.notifier).reset();
      container.dispose();
    });
    container
        .read(focusProvider.notifier)
        .startSession(25, ExitChallengeLevel.strict, null);

    await tester.pumpWidget(appWithRouter(container));
    await tester.pump();

    await tester.tap(find.text("I can't hold on - exit early"));
    await tester.pumpAndSettle();

    // 第 3 档：倒计时未结束，确认退出按钮不出现
    // Level 3: the confirm button stays hidden until the countdown ends
    expect(find.text('Confirm exit'), findsNothing);

    // 回去继续专注
    // Go back and keep focusing
    await tester.tap(find.text("Never mind, I'll hold on a bit longer"));
    await tester.pumpAndSettle();
    expect(find.text('Focusing'), findsOneWidget);

    container.read(focusProvider.notifier).reset();
  });

  testWidgets('gentle: 点提前退出直接中断，跳回首页 / gentle: early exit interrupts immediately and jumps home',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(focusProvider.notifier)
        .startSession(25, ExitChallengeLevel.gentle, null);

    await tester.pumpWidget(appWithRouter(container));
    await tester.pump();

    await tester.tap(find.text("I can't hold on - exit early"));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.text('HOME'), findsOneWidget);
    expect(container.read(focusProvider).status, FocusStatus.idle);
    container.read(focusProvider.notifier).reset();
  });
}
