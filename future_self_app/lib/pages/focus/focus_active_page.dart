import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/focus_controller.dart';

class FocusActivePage extends ConsumerWidget {
  const FocusActivePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(focusProvider);
    final controller = ref.read(focusProvider.notifier);

    // 会话已结束（完成/放弃）→ 记账后回首页（结果反馈由首页展示）
    // 先于 idle 分支判断：reset() 会把状态归 idle，若 idle 分支在前会竞争导航
    if (state.status == FocusStatus.completed ||
        state.status == FocusStatus.abandoned) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.reset();
        if (context.mounted) context.go('/home');
      });
      return const SizedBox.shrink();
    }

    // 无进行中的会话且从未启动过（刷新页面后内存状态丢失）→ 弹回发起页，避免死页。
    // hasEverStarted 防止与"会话结束跳首页"的导航竞争。
    if (state.status == FocusStatus.idle && !state.hasEverStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/focus');
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

    // 第 2 档输入承诺文字 / 第 3 档强制倒计时，走 router 管理的挑战页
    context.go('/focus/exit-challenge');
  }
}
