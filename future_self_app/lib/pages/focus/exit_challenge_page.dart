import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/contract.dart';
import '../../state/focus_controller.dart';

/// Early exit challenge page:
/// Tier 2 (firm) -> requires the words the user wrote when signing the contract;
/// Tier 3 (strict) -> forces a 60-second countdown; the exit button appears only after it ends.
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
        ? 'I will take responsibility for myself'
        : 'I will take responsibility for my future';
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
    // The user gives up on exiting -> close the challenge page and keep focusing
    ref.read(focusProvider.notifier).cancelChallenge();
    context.go('/focus/active');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(focusProvider);
    final isStrict = state.exitChallengeLevel == ExitChallengeLevel.strict;
    final countdownDone = state.challengeRemaining <= Duration.zero;

    // Session abandoned -> return home (FocusActivePage shows the result in a SnackBar)
    if (state.status == FocusStatus.abandoned ||
        state.status == FocusStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(focusProvider.notifier).reset();
        if (context.mounted) context.go('/home');
      });
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.grey.shade900,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Really give up?'),
          actions: [
            TextButton(
              onPressed: _giveUpExit,
              child: const Text('Keep focusing', style: TextStyle(color: Colors.white70)),
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
                    'What you wrote before you started:\n"${state.commitmentText}"',
                    style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
                  ),
                  const SizedBox(height: 24),
                ],
                if (isStrict) ...[
                  Text(
                    countdownDone
                        ? "60 seconds have passed. Exiting now will interrupt today's focus."
                        : 'Cool-down: ${state.challengeRemaining.inSeconds}s left.\nThe exit button stays hidden until the countdown ends.',
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
                      child: const Text('Confirm exit'),
                    ),
                ] else ...[
                  Text(
                    'Type "$_requiredText" to exit.\nThis is the gate you set for yourself when you signed.',
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
                    child: const Text('Confirm exit'),
                  ),
                ],
                const Spacer(),
                TextButton(
                  onPressed: _giveUpExit,
                  child: const Text(
                    "Never mind, I'll hold on a bit longer",
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
