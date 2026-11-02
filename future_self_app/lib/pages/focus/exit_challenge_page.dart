import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/contract.dart';
import '../../state/focus_controller.dart';

/// 提前退出挑战页：
/// 第 2 档（firm）→ 要求输入自己签署契约时写给自己的话；
/// 第 3 档（strict）→ 强制 60 秒倒计时，结束后才出现退出按钮。
class ExitChallengePage extends ConsumerStatefulWidget {
  const ExitChallengePage({super.key});

  @override
  ConsumerState<ExitChallengePage> createState() => _ExitChallengePageState();
}

class _ExitChallengePageState extends ConsumerState<ExitChallengePage> {
  final _textController = TextEditingController();
  Timer? _ticker;
  late String _requiredText;

  @override
  void initState() {
    super.initState();
    final state = ref.read(focusProvider);
    _requiredText = state.exitChallengeLevel == ExitChallengeLevel.strict
        ? '我要对自己负责'
        : '我要对自己的未来负责';
    if (state.exitChallengeLevel == ExitChallengeLevel.strict) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (ref.read(focusProvider).challengeRemaining <= Duration.zero) {
          _ticker?.cancel();
          if (mounted) setState(() {});
        } else if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _giveUpExit() {
    // 用户认输放弃退出 → 关闭挑战页回去继续专注
    ref.read(focusProvider.notifier).cancelChallenge();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(focusProvider);
    final isStrict = state.exitChallengeLevel == ExitChallengeLevel.strict;
    final countdownDone = state.challengeRemaining <= Duration.zero;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.grey.shade900,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('真的要放弃吗？'),
          actions: [
            TextButton(
              onPressed: _giveUpExit,
              child: const Text('继续专注', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.commitmentText?.isNotEmpty == true) ...[
                  Text(
                    '你开始前写下的话：\n「${state.commitmentText}」',
                    style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
                  ),
                  const SizedBox(height: 24),
                ],
                if (isStrict) ...[
                  Text(
                    countdownDone
                        ? '60 秒已过。现在退出，今天的专注将中断。'
                        : '冷静倒计时 ${state.challengeRemaining.inSeconds} 秒。\n倒数结束前，退出按钮不会出现。',
                    style: TextStyle(
                      color: countdownDone ? Colors.white : Colors.amber,
                      fontSize: 18,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (countdownDone)
                    FilledButton(
                      onPressed: () =>
                          ref.read(focusProvider.notifier).confirmExitAfterCountdown(),
                      child: const Text('确认退出'),
                    ),
                ] else ...[
                  Text(
                    '输入「$_requiredText」即可退出。\n这是你签约时为自己设下的关卡。',
                    style: const TextStyle(color: Colors.white70, fontSize: 18, height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _textController.text.trim() == _requiredText
                        ? () =>
                            ref.read(focusProvider.notifier).confirmExitWithText()
                        : null,
                    child: const Text('确认退出'),
                  ),
                ],
                const Spacer(),
                TextButton(
                  onPressed: _giveUpExit,
                  child: const Text(
                    '算了，我再撑一会儿',
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
}
