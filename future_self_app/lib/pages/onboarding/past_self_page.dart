import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/contract.dart';
import '../../state/onboarding_controller.dart';

class PastSelfPage extends ConsumerStatefulWidget {
  const PastSelfPage({super.key});

  @override
  ConsumerState<PastSelfPage> createState() => _PastSelfPageState();
}

class _PastSelfPageState extends ConsumerState<PastSelfPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('过去的我 · 1/2')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '先诚实面对过去的自己。\n这些都不会被任何人看到，只存放在你的手机里。',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Text('你的性格里有这些吗？', style: _sectionTitle(context)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in PersonalityTag.values)
                FilterChip(
                  label: Text(tag.label),
                  selected: state.personalityTags.contains(tag),
                  onSelected: (_) => controller.toggleTag(tag),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('哪些坏习惯在偷走你的时间？', style: _sectionTitle(context)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final habit in BadHabit.values)
                FilterChip(
                  label: Text(habit.label),
                  selected: state.badHabits.contains(habit),
                  onSelected: (_) => controller.toggleHabit(habit),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('你估计自己每天刷手机多久？', style: _sectionTitle(context)),
          const SizedBox(height: 8),
          Text(
            '${state.estimatedScreenMinutes ~/ 60} 小时 ${state.estimatedScreenMinutes % 60} 分钟',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Slider(
            value: state.estimatedScreenMinutes.toDouble(),
            min: 30,
            max: 600,
            divisions: 19,
            label: '${state.estimatedScreenMinutes} 分钟',
            onChanged: (v) => controller.setEstimatedScreenMinutes(v.round()),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => context.go('/onboarding/future'),
            child: const Text('下一步：未来的我'),
          ),
        ],
      ),
    );
  }

  TextStyle _sectionTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
          );
}
