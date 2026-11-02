import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/contract.dart';
import '../../state/active_contract_provider.dart';
import '../../state/focus_controller.dart';
import '../widgets/focus_preset_selector.dart';

class FocusStartPage extends ConsumerStatefulWidget {
  const FocusStartPage({super.key});

  @override
  ConsumerState<FocusStartPage> createState() => _FocusStartPageState();
}

class _FocusStartPageState extends ConsumerState<FocusStartPage> {
  int _selectedMinutes = 25;
  final _commitmentController = TextEditingController();

  @override
  void dispose() {
    _commitmentController.dispose();
    super.dispose();
  }

  void _start() {
    final focus = ref.read(focusProvider.notifier);
    final contractAsync = ref.read(activeContractProvider);
    final level = contractAsync.value?.exitChallengeLevel ?? ExitChallengeLevel.firm;

    focus.startSession(_selectedMinutes, level, _commitmentController.text.trim());
    context.go('/focus/active');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('开始专注')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('选择专注时长'),
          const SizedBox(height: 12),
          FocusPresetSelector(
            selected: _selectedMinutes,
            onChanged: (m) => setState(() => _selectedMinutes = m),
          ),
          const SizedBox(height: 24),
          const Text('这段时间你打算做什么？（可选，退出挑战时会看见）'),
          const SizedBox(height: 8),
          TextField(
            controller: _commitmentController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: '例如：背完第 3 单元单词',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.play_arrow),
            label: Text('进入专注 · $_selectedMinutes 分钟'),
          ),
        ],
      ),
    );
  }
}
