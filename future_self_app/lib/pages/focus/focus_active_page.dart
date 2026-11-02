import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/contract.dart';
import '../../state/focus_controller.dart';
import 'exit_challenge_page.dart';

class FocusActivePage extends ConsumerWidget {
  const FocusActivePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(focusProvider);
    final controller = ref.read(focusProvider.notifier);

    // 会话已结束（完成/放弃）→ 展示结果并回首页
    if (state.status == FocusStatus.completed ||
        state.status == FocusStatus.abandoned) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final completed = state.status == FocusStatus.completed;
        controller.reset();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(completed
                ? '专注完成，干得漂亮！'
                : '本次专注中断了，明天继续。'),
          ),
        );
        context.go('/home');
      });
    }

    final remaining = state.remainingSeconds;
    final mm = (remaining ~/ 60).toString().padLeft(2, '0');
    final ss = (remaining % 60).toString().padLeft(2, '0');
    final progress = state.plannedMinutes == null
        ? 0.0
        : 1 - remaining / (state.plannedMinutes! * 60);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.indigo.shade900,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('专注中',
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 24),
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 260,
                        height: 260,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 10,
                          backgroundColor: Colors.indigo.shade700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$mm:$ss',
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFeatures: [],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (state.commitmentText?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      '「${state.commitmentText}」',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ),
                const SizedBox(height: 48),
                TextButton(
                  onPressed: () => _onExitPressed(context, ref, state),
                  child: const Text(
                    '坚持不住，想提前退出',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onExitPressed(
      BuildContext context, WidgetRef ref, FocusSessionState state) {
    final controller = ref.read(focusProvider.notifier);
    final allowed = controller.requestExit();

    if (allowed) {
      return; // 第 1 档直接退出，状态变更后本页自动跳转
    }

    if (state.exitChallengeLevel == ExitChallengeLevel.strict) {
      // 第 3 档：改为按钮按下后再触发倒计时展示
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ExitChallengePage(),
          fullscreenDialog: true,
        ),
      );
    } else {
      // 第 2 档：输入承诺文字
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ExitChallengePage(),
          fullscreenDialog: true,
        ),
      );
    }
  }
}
