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
      appBar: AppBar(title: const Text('Past Self - 1/2')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Be honest about who you have been.\nNo one else will ever see this; it stays on your phone.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Text('Do any of these describe you?', style: _sectionTitle(context)),
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
          Text('Which bad habits are stealing your time?', style: _sectionTitle(context)),
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
          Text('Roughly how long are you on your phone each day?', style: _sectionTitle(context)),
          const SizedBox(height: 8),
          Text(
            '${state.estimatedScreenMinutes ~/ 60} h ${state.estimatedScreenMinutes % 60} min',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Slider(
            value: state.estimatedScreenMinutes.toDouble(),
            min: 30,
            max: 600,
            divisions: 19,
            label: '${state.estimatedScreenMinutes} min',
            onChanged: (v) => controller.setEstimatedScreenMinutes(v.round()),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => context.go('/onboarding/future'),
            child: const Text('Next: Future Self'),
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
