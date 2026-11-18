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

    // Session ended (completed / abandoned) -> record it and return home (home shows the result)
    // Check before the idle branch: reset() sets state to idle, so an earlier idle branch would race the navigation
    if (state.status == FocusStatus.completed ||
        state.status == FocusStatus.abandoned) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.reset();
        if (context.mounted) context.go('/home');
      });
      return const SizedBox.shrink();
    }

    // No running session and none was ever started (memory state lost on refresh) -> bounce back to the start page to avoid a dead page.
    // hasEverStarted prevents a race with the "session ended -> jump home" navigation.
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
                const Text('Focusing',
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
                    "I can't hold on - exit early",
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
      return; // Tier 1 exits directly; this page navigates itself after the state change
    }

    // Tier 2 asks for the commitment text / tier 3 forces a countdown; both go through the router-managed challenge page
    context.go('/focus/exit-challenge');
  }
}
