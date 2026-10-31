import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/contract.dart';
import '../../state/onboarding_controller.dart';

class FutureSelfPage extends ConsumerStatefulWidget {
  const FutureSelfPage({super.key});

  @override
  ConsumerState<FutureSelfPage> createState() => _FutureSelfPageState();
}

class _FutureSelfPageState extends ConsumerState<FutureSelfPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('未来的我 · 2/2')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('现在，见见未来的自己。'),
          const SizedBox(height: 24),
          Text('你想朝哪个方向发展？', style: _sectionTitle(context)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in GoalDirection.values)
                ChoiceChip(
                  label: Text(d.label),
                  selected: state.direction == d,
                  onSelected: (_) => controller.setDirection(d),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('给自己多长时间？', style: _sectionTitle(context)),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 90, label: Text('3 个月')),
              ButtonSegment(value: 180, label: Text('半年')),
              ButtonSegment(value: 365, label: Text('1 年')),
            ],
            selected: {_monthsFromNow(state.targetDate)},
            onSelectionChanged: (months) => controller.setTargetDate(
              DateTime.now().add(Duration(days: months.first)),
            ),
          ),
          const SizedBox(height: 24),
          Text('每天愿意投入多少专注时间？', style: _sectionTitle(context)),
          const SizedBox(height: 8),
          Text(
            '${state.committedFocusMinutes} 分钟',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Slider(
            value: state.committedFocusMinutes.toDouble(),
            min: 15,
            max: 240,
            divisions: 15,
            label: '${state.committedFocusMinutes} 分钟',
            onChanged: (v) => controller.setCommittedFocusMinutes(v.round()),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: state.direction == null
                ? null
                : () => context.go('/onboarding/contract'),
            child: const Text('生成我的自律契约'),
          ),
        ],
      ),
    );
  }

  int _monthsFromNow(DateTime? targetDate) {
    if (targetDate == null) return 180;
    final days = targetDate.difference(DateTime.now()).inDays;
    if (days <= 100) return 90;
    if (days <= 270) return 180;
    return 365;
  }

  TextStyle _sectionTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
          );
}
